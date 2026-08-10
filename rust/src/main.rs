use bluer::{Adapter, AdapterEvent, Session};
use futures::StreamExt;
use serde::Serialize;
use std::sync::Arc;
use tokio::io::{self, AsyncBufReadExt, BufReader};

#[derive(Serialize, Clone)]
struct DeviceInfo {
    mac: String,
    name: String,
    icon: String,
    connected: bool,
    battery: u8,
}

#[derive(Serialize, Clone)]
struct BtState {
    powered: bool,
    devices: Vec<DeviceInfo>,
}

// Bepaalt het juiste Nerd Font icoon op basis van de BlueZ class/icon
fn get_icon_for_device(icon_name: &str) -> String {
    match icon_name {
        "audio-headset" | "audio-headphones" => "".to_string(),
        "audio-card" => "󰓃".to_string(),
        "input-mouse" => "󰍽".to_string(),
        "input-keyboard" => "".to_string(),
        "phone" | "smartphone" => "".to_string(),
        "computer" => "󰌢".to_string(),
        "input-gaming" => "".to_string(),
        _ => "".to_string(), // Fallback generiek BT icoon
    }
}

async fn generate_state(adapter: &Adapter) -> bluer::Result<BtState> {
    let powered = adapter.is_powered().await?;
    let mut devices = Vec::new();

    if powered {
        for mac in adapter.device_addresses().await? {
            let device = adapter.device(mac)?;

            // We tonen enkel apparaten die al gekoppeld (paired) zijn.
            if let Ok(true) = device.is_paired().await {
                // device.name() geeft Result<Option<String>, bluer::Error>
                let name = device
                    .name()
                    .await?
                    .unwrap_or_else(|| mac.to_string());

                let connected = device.is_connected().await.unwrap_or(false);

                // device.icon() geeft Result<Option<String>, bluer::Error>
                let icon_str = device
                    .icon()
                    .await?
                    .unwrap_or_default();

                // Batterijpercentage kan optioneel via DBus properties worden uitgelezen; we zetten hier 0
                let battery = 0;

                devices.push(DeviceInfo {
                    mac: mac.to_string(),
                    name,
                    icon: get_icon_for_device(&icon_str),
                    connected,
                    battery,
                });
            }
        }
    }

    Ok(BtState { powered, devices })
}

async fn print_state(adapter: &Adapter) {
    if let Ok(state) = generate_state(adapter).await {
        if let Ok(json) = serde_json::to_string(&state) {
            println!("{}", json);
        }
    }
}

#[tokio::main]
async fn main() -> bluer::Result<()> {
    let session = Session::new().await?;
    let adapter = Arc::new(session.default_adapter().await?);

    // Initial state print
    print_state(&adapter).await;

    let adapter_clone = adapter.clone();

    // Task 1: Luister naar BlueZ adapter events (connecties, power status wijzigingen)
    tokio::spawn(async move {
        if let Ok(mut events) = adapter_clone.events().await {
            while let Some(_event) = events.next().await {
                // Elke keer als er iets gebeurt op de adapter, print de nieuwe JSON state
                print_state(&adapter_clone).await;
            }
        }
    });

    // Task 2: Luister naar stdin voor commando's van Quickshell
    let mut stdin = BufReader::new(io::stdin()).lines();
    while let Ok(Some(line)) = stdin.next_line().await {
        let parts: Vec<&str> = line.trim().split_whitespace().collect();
        if parts.is_empty() {
            continue;
        }

        match parts[0] {
            "power" if parts.len() == 2 => {
                let turn_on = parts[1] == "on";
                let _ = adapter.set_powered(turn_on).await;
                print_state(&adapter).await;
            }
            "connect" if parts.len() == 2 => {
                if let Ok(mac) = parts[1].parse::<bluer::Address>() {
                    if let Ok(device) = adapter.device(mac) {
                        let _ = device.connect().await;
                        print_state(&adapter).await;
                    }
                }
            }
            "disconnect" if parts.len() == 2 => {
                if let Ok(mac) = parts[1].parse::<bluer::Address>() {
                    if let Ok(device) = adapter.device(mac) {
                        let _ = device.disconnect().await;
                        print_state(&adapter).await;
                    }
                }
            }
            _ => {}
        }
    }

    Ok(())
}
