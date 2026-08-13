use bluer::{Adapter, Session};
use serde::Serialize;
use std::sync::Arc;

#[derive(Serialize, Clone)]
pub struct DeviceInfo {
    pub mac: String,
    pub name: String,
    pub icon: String,
    pub connected: bool,
    pub battery: u8,
}

#[derive(Serialize, Clone)]
pub struct BtState {
    pub powered: bool,
    pub devices: Vec<DeviceInfo>,
}

pub struct BluetoothModule {
    pub adapter: Arc<Adapter>,
}

impl BluetoothModule {
    pub async fn new() -> Result<Self, Box<dyn std::error::Error>> {
        let session = Session::new().await?;
        let adapter = Arc::new(session.default_adapter().await?);
        Ok(Self { adapter })
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

    pub async fn generate_state(&self) -> bluer::Result<BtState> {
        let powered = self.adapter.is_powered().await?;
        let mut devices = Vec::new();

        if powered {
            for mac in self.adapter.device_addresses().await? {
                let device = self.adapter.device(mac)?;

                if let Ok(true) = device.is_paired().await {
                    let name = device.name().await?.unwrap_or_else(|| mac.to_string());
                    let connected = device.is_connected().await.unwrap_or(false);
                    let icon_str = device.icon().await?.unwrap_or_default();
                    let battery = 0;

                    devices.push(DeviceInfo {
                        mac: mac.to_string(),
                        name,
                        icon: BluetoothModule::get_icon_for_device(&icon_str),
                        connected,
                        battery,
                    });
                }
            }
        }

        Ok(BtState { powered, devices })
    }

    pub async fn print_state(&self) {
        if let Ok(state) = self.generate_state().await {
            if let Ok(json) = serde_json::to_string(&state) {
                // We sturen een type mee zodat QML weet wat het is
                println!("{{\"type\":\"bluetooth\", \"data\":{}}}", json);
            }
        }
    }

    pub async fn handle_command(&self, cmd: &str, args: &[&str]) {
        match cmd {
            "scan" => {
                let adapter_clone = self.adapter.clone();
                tokio::spawn(async move {
                    if let Ok(_stream) = adapter_clone.discover_devices().await {
                        tokio::time::sleep(std::time::Duration::from_secs(10)).await;
                    }
                });
            }
            "connect" if args.len() == 1 => {
                if let Ok(mac) = args[0].parse::<bluer::Address>() {
                    if let Ok(device) = self.adapter.device(mac) {
                        let _ = device.connect().await;
                    }
                }
            }
            "disconnect" if args.len() == 1 => {
                if let Ok(mac) = args[0].parse::<bluer::Address>() {
                    if let Ok(device) = self.adapter.device(mac) {
                        let _ = device.disconnect().await;
                    }
                }
            }
            "unpair" if args.len() == 1 => {
                if let Ok(mac) = args[0].parse::<bluer::Address>() {
                    let _ = self.adapter.remove_device(mac).await;
                }
            }
            _ => {}
        }
        self.print_state().await;
    }
}
