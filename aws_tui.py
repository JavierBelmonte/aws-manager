import configparser
import os
import shutil
from pathlib import Path
from typing import List, Tuple

from textual.app import App, ComposeResult
from textual.containers import Container, Horizontal, Vertical
from textual.screen import Screen, ModalScreen
from textual.widgets import Header, Footer, ListView, ListItem, Label, Button, Input, Static
from textual.reactive import reactive
from textual.binding import Binding

# --- Logic / Backend ---

CREDENTIALS_PATH = Path.home() / ".aws" / "credentials"

class AwsCredentialsManager:
    def __init__(self, path: Path = CREDENTIALS_PATH):
        self.path = path
        self.config = configparser.ConfigParser()
        self.ensure_params()

    def ensure_params(self):
        if not self.path.parent.exists():
            self.path.parent.mkdir(parents=True, exist_ok=True)
        if not self.path.exists():
            self.path.touch()

    def load(self):
        self.config.read(self.path)

    def get_profiles(self) -> List[str]:
        self.load()
        # Return all sections except 'default'
        return [sec for sec in self.config.sections() if sec != "default"]

    def get_profile_details(self, profile: str) -> dict:
        self.load()
        if profile in self.config:
            return dict(self.config[profile])
        return {}

    def add_profile(self, name: str, access_key: str, secret_key: str, session_token: str = ""):
        self.load()
        # Create backup only once per run or check if exists? 
        # For safety, let's just backup before write.
        shutil.copy(self.path, self.path.with_suffix(".bak"))
        
        if not self.config.has_section(name):
            self.config.add_section(name)
        
        self.config[name]["aws_access_key_id"] = access_key
        self.config[name]["aws_secret_access_key"] = secret_key
        if session_token:
             self.config[name]["aws_session_token"] = session_token

        with open(self.path, "w") as f:
            self.config.write(f)

    def set_default(self, source_profile: str):
        self.load()
        if source_profile not in self.config:
            return
        
        # Backup
        shutil.copy(self.path, self.path.with_suffix(".bak"))

        if not self.config.has_section("default"):
            self.config.add_section("default")

        # Clear existing default
        self.config.remove_section("default")
        self.config.add_section("default")

        # Copy keys
        for key, value in self.config[source_profile].items():
            self.config["default"][key] = value

        with open(self.path, "w") as f:
            self.config.write(f)

# --- UI / Frontend ---

class AddProfileScreen(ModalScreen):
    BINDINGS = [("escape", "cancel", "Cancel")]

    def compose(self) -> ComposeResult:
        yield Vertical(
            Label("Add New AWS Profile", classes="header"),
            Input(placeholder="Profile Name", id="p_name"),
            Input(placeholder="AWS Access Key ID", id="p_key"),
            Input(placeholder="AWS Secret Access Key", id="p_secret", password=True),
            Horizontal(
                Button("Cancel", variant="error", id="cancel"),
                Button("Save", variant="success", id="save"),
                classes="buttons"
            ),
            classes="modal_container"
        )

    def on_button_pressed(self, event: Button.Pressed) -> None:
        if event.button.id == "cancel":
            self.dismiss()
        elif event.button.id == "save":
            name = self.query_one("#p_name", Input).value
            key = self.query_one("#p_key", Input).value
            secret = self.query_one("#p_secret", Input).value
            
            if name and key and secret:
                manager = AwsCredentialsManager()
                manager.add_profile(name, key, secret)
                self.dismiss(True) # Return true to indicate success

    def action_cancel(self):
        self.dismiss()

class ProfileItem(ListItem):
    def __init__(self, name: str) -> None:
        super().__init__()
        self.profile_name = name

    def compose(self) -> ComposeResult:
        yield Label(self.profile_name)

class AWSTuiApp(App):
    CSS = """
    Screen {
        layout: horizontal;
    }
    
    .sidebar {
        width: 30%;
        background: $panel;
        border-right: heavy $background;
    }
    
    .content {
        width: 70%;
        padding: 2;
    }
    
    .modal_container {
        padding: 4;
        width: 60%;
        height: auto;
        border: thick $success;
        background: $surface;
        align: center middle;
    }

    .header {
        text-align: center;
        text-style: bold;
        margin-bottom: 2;
    }

    .buttons {
        align: center middle;
        margin-top: 2;
    }
    
    Button {
        margin: 1;
    }
    
    #active_profile_display {
        background: $success;
        color: auto;
        padding: 1;
        margin-bottom: 2;
        text-align: center;
    }
    """

    BINDINGS = [
        Binding("q", "quit", "Quit"),
        Binding("a", "add_profile", "Add Profile"),
    ]

    def compose(self) -> ComposeResult:
        yield Header()
        yield Container(
            Vertical(
                Label("Available Profiles", classes="header"),
                ListView(id="profile_list"),
                classes="sidebar"
            ),
            Vertical(
                Label("No profile selected", id="status_label"),
                Static(id="details_view"),
                Button("ACTIVATE THIS PROFILE", id="activate_btn", disabled=True),
                classes="content"
            )
        )
        yield Footer()

    def on_mount(self) -> None:
        self.refresh_profiles()

    def refresh_profiles(self):
        manager = AwsCredentialsManager()
        profiles = manager.get_profiles()
        
        list_view = self.query_one("#profile_list", ListView)
        list_view.clear()
        
        for p in profiles:
            list_view.append(ProfileItem(p))

    def on_list_view_selected(self, event: ListView.Selected) -> None:
        item = event.item
        if isinstance(item, ProfileItem):
            self.selected_profile = item.profile_name
            self.query_one("#status_label", Label).update(f"Selected: {self.selected_profile}")
            
            # Show details
            manager = AwsCredentialsManager()
            details = manager.get_profile_details(self.selected_profile)
            masked_key = details.get("aws_access_key_id", "")[:4] + "..."
            
            self.query_one("#details_view", Static).update(
                f"Access Key: {masked_key}\n"
                f"Secret Key: ************"
            )
            
            self.query_one("#activate_btn", Button).disabled = False

    def on_button_pressed(self, event: Button.Pressed) -> None:
        if event.button.id == "activate_btn":
            if hasattr(self, 'selected_profile'):
                manager = AwsCredentialsManager()
                manager.set_default(self.selected_profile)
                self.notify(f"Profile '{self.selected_profile}' is now DEFAULT!")

    def action_add_profile(self) -> None:
        def check_result(added: bool | None) -> None:
            if added:
                self.refresh_profiles()
                self.notify("Profile added successfully!")
                
        self.push_screen(AddProfileScreen(), check_result)

if __name__ == "__main__":
    app = AWSTuiApp()
    app.run()
