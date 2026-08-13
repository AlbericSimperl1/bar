use serde::Serialize;
use std::process::Command;

#[derive(Serialize, Clone)]
pub struct WifiNetwork {
    pub ssid: String,
    pub signal: u8,
    pub secured: bool,
    pub active: bool,
}

#[derive(Serialize, Clone)]
pub struct NetState {
    pub wifi_enabled: bool,
    pub connected_ssid: String,
    pub networks: Vec<WifiNetwork>,
}

pub struct NetworkModule;

impl NetworkModule {
    pub fn new() -> Result<Self, Box<dyn std::error::Error>> {
        Ok(Self)
    }

    pub fn generate_state(&self) -> Result<NetState, Box<dyn std::error::Error>> {
        // Controleer of wifi aan staat
        let wifi_enabled_output = Command::new("nmcli")
            .args(["-t", "-f", "WIFI", "radio", "wifi"])
            .output()?;
        let wifi_enabled = String::from_utf8_lossy(&wifi_enabled_output.stdout).trim() == "enabled";

        let mut networks = Vec::new();
        let mut connected_ssid = String::new();

        if wifi_enabled {
            // Haal de netwerken op (--rescan no voorkomt dat de terminal blokkeert tijdens het scannen)
            let output = Command::new("nmcli")
                .args([
                    "-t",
                    "-f",
                    "ACTIVE,SSID,SIGNAL,SECURITY",
                    "device",
                    "wifi",
                    "list",
                    "--rescan",
                    "no",
                ])
                .output()?;

            let stdout = String::from_utf8_lossy(&output.stdout);
            for line in stdout.lines() {
                let parts: Vec<&str> = line.split(':').collect();
                if parts.len() < 4 {
                    continue;
                }

                let active = parts[0] == "yes";
                let ssid = parts[1].to_string();
                if ssid.is_empty() {
                    continue;
                }

                let signal = parts[2].parse::<u8>().unwrap_or(0);
                let secured = !parts[3].is_empty();

                if active {
                    connected_ssid = ssid.clone();
                }

                networks.push(WifiNetwork {
                    ssid,
                    signal,
                    secured,
                    active,
                });
            }

            // Sorteren: actieve bovenaan, dan sterkste signaal
            networks.sort_by(|a, b| {
                if a.active != b.active {
                    return b.active.cmp(&a.active);
                }
                b.signal.cmp(&a.signal)
            });
        }

        Ok(NetState {
            wifi_enabled,
            connected_ssid,
            networks,
        })
    }

    pub fn print_state(&self) {
        match self.generate_state() {
            Ok(state) => {
                if let Ok(json) = serde_json::to_string(&state) {
                    // We sturen een type mee zodat QML weet wat het is
                    println!("{{\"type\":\"network\", \"data\":{}}}", json);
                }
            }
            Err(e) => eprintln!("Netwerk fout: {}", e),
        }
    }

    pub fn handle_command(&self, cmd: &str, args: &[&str]) {
        match cmd {
            "scan" => {
                // Forceer een nieuwe scan in de achtergrond
                let _ = Command::new("nmcli")
                    .args(["device", "wifi", "rescan"])
                    .spawn();
            }
            "connect" if !args.is_empty() => {
                let ssid = args.join(" ");
                eprintln!(
                    "Verbinden met {} (wachtwoord prompt moet nog geïmplementeerd worden)",
                    ssid
                );
            }
            _ => {}
        }
        self.print_state();
    }
}
