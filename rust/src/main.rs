mod modules;

use crate::modules::bluetooth::BluetoothModule;
use crate::modules::network::NetworkModule;
use futures::StreamExt;
use std::sync::Arc;
use tokio::io::{self, AsyncBufReadExt, BufReader};

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    // Initialiseer modules
    let bt = Arc::new(BluetoothModule::new().await?);
    let net = Arc::new(NetworkModule::new()?);

    // Print initiële states
    bt.print_state().await;
    net.print_state();

    // Start Bluetooth event listener in de achtergrond
    let bt_clone = bt.clone();
    tokio::spawn(async move {
        if let Ok(mut events) = bt_clone.adapter.events().await {
            while let Some(_event) = events.next().await {
                bt_clone.print_state().await;
            }
        }
    });

    // Start Network poller in de achtergrond (elke 10 sec netwerken scannen)
    let net_clone = net.clone();
    tokio::spawn(async move {
        let mut interval = tokio::time::interval(std::time::Duration::from_secs(10));
        loop {
            interval.tick().await;
            net_clone.print_state();
        }
    });

    // Lees commando's van Quickshell (stdin)
    let mut stdin = BufReader::new(io::stdin()).lines();
    while let Ok(Some(line)) = stdin.next_line().await {
        let parts: Vec<&str> = line.trim().split_whitespace().collect();
        if parts.is_empty() {
            continue;
        }

        let module = parts[0];
        let cmd = if parts.len() > 1 { parts[1] } else { "" };
        let args = &parts[2..];

        match module {
            "bt" => bt.handle_command(cmd, args).await,
            "net" => net.handle_command(cmd, args),
            _ => {}
        }
    }

    Ok(())
}
