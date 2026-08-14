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

fn get_icon_for_device(icon_name: &str) -> String {
    match icon_name {
        "audio-headset" | "audio-headphones" => "".to_string(),
        "audio-card" => "󰓃".to_string(),
        "input-mouse" => "󰍽".to_string(),
        "input-keyboard" => "".to_string(),
        "phone" | "smartphone" => "".to_string(),
        "computer" => "󰌢".to_string(),
        "input-gaming" => "".to_string(),
        _ => "".to_string(),
    }
}

async fn generate_state(adapter: &Adapter) -> bluer::Result<BtState> {
    let powered = adapter.is_powered().await?;
    let mut devices = Vec::new();

    if powered {
        for mac in adapter.device_addresses().await? {
            let device = adapter.device(mac)?;

            if let Ok(true) = device.is_paired().await {
                let name = device.name().await?.unwrap_or_else(|| mac.to_string());
                let connected = device.is_connected().await.unwrap_or(false);
                let icon_str = device.icon().await?.unwrap_or_default();
                let battery = 0; // Nog in te vullen via DBus als je dat wilt

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
    match generate_state(adapter).await {
        Ok(state) => {
            if let Ok(json) = serde_json::to_string(&state) {
                println!("{}", json);
            }
        }
        Err(e) => {
            // Als er een fout is, print deze naar stderr zodat we het in Quickshell kunnen zien!
            eprintln!("Bluetooth fout: {}", e);
        }
    }
}

#[tokio::main]
async fn main() -> bluer::Result<()> {
    let session = Session::new().await?;
    let adapter = Arc::new(session.default_adapter().await?);

    print_state(&adapter).await;

    let adapter_clone = adapter.clone();

    // Task 1: Luister naar BlueZ events
    tokio::spawn(async move {
        if let Ok(mut events) = adapter_clone.events().await {
            while let Some(_event) = events.next().await {
                print_state(&adapter_clone).await;
            }
        }
    });

    // Task 2: Luister naar stdin voor commando's vanuit Quickshell
    let mut stdin = BufReader::new(io::stdin()).lines();
    while let Ok(Some(line)) = stdin.next_line().await {
        let parts: Vec<&str> = line.trim().split_whitespace().collect();
        if parts.is_empty() {
            continue;
        }

        match parts[0] {
            "scan" => {
                let adapter_clone = adapter.clone();
                // Start scanning voor 10 seconden
                tokio::spawn(async move {
                    if let Ok(_stream) = adapter_clone.discover_devices().await {
                        tokio::time::sleep(std::time::Duration::from_secs(10)).await;
                    }
                });
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
            "unpair" if parts.len() == 2 => {
                if let Ok(mac) = parts[1].parse::<bluer::Address>() {
                    if let Ok(device) = adapter.device(mac) {
                        let _ = adapter.remove_device(mac).await; // Verwijdert/unpaired het apparaat
                        print_state(&adapter).await;
                    }
                }
            }
            _ => {}
        }
    }

    Ok(())
}
