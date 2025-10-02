import os
from installer_components.install_data import get_install_items

class InstallerCore:
    def __init__(self, repo_dir):
        self.repo_dir = repo_dir
        self.installation_items = []
        self.selected_item_funcs = set()
        self._load_installation_items()

    def _load_installation_items(self):
        # Load items from install_data.py
        raw_items = get_install_items(self.repo_dir)
        
        # Process raw items to include a unique identifier and initial selection state
        # We'll use the index as a temporary unique ID for now, or func if it's unique
        for i, item in enumerate(raw_items):
            if item["type"] != "header":
                item["_id"] = item.get("func", f"item_{i}") # Use func as ID if available, else index
                item["is_selected"] = False # Initial state
            self.installation_items.append(item)

    def get_display_items(self):
        """Returns items suitable for display in the GUI, including their selection state."""
        return self.installation_items

    def update_item_selection(self, item_id, is_selected):
        """Updates the selection state of a specific item by its ID."""
        for item in self.installation_items:
            if item.get("_id") == item_id:
                item["is_selected"] = is_selected
                if is_selected:
                    if "func" in item:
                        self.selected_item_funcs.add(item["func"])
                else:
                    if "func" in item and item["func"] in self.selected_item_funcs:
                        self.selected_item_funcs.remove(item["func"])
                return
        raise ValueError(f"Item with ID {item_id} not found.")

    def select_all(self):
        """Selects all checkable installation items."""
        for item in self.installation_items:
            if item["type"] != "header":
                item["is_selected"] = True
                if "func" in item:
                    self.selected_item_funcs.add(item["func"])

    def deselect_all(self):
        """Deselects all checkable installation items."""
        for item in self.installation_items:
            if item["type"] != "header":
                item["is_selected"] = False
        self.selected_item_funcs.clear()

    def select_essential(self):
        """Selects essential installation items (type 'essential')."""
        self.deselect_all() # Start fresh
        for item in self.installation_items:
            if item.get("type") == "essential":
                item["is_selected"] = True
                if "func" in item:
                    self.selected_item_funcs.add(item["func"])

    def select_essential_laptop(self):
        """Selects essential and essential_laptop installation items."""
        self.deselect_all() # Start fresh
        for item in self.installation_items:
            if item.get("type") in ["essential", "essential_laptop"]:
                item["is_selected"] = True
                if "func" in item:
                    self.selected_item_funcs.add(item["func"])

    def get_selected_commands(self):
        """Returns an ordered list of 'func' strings for all currently selected items."""
        ordered_commands = []
        # Maintain order as defined in install_data.py
        for item_data in self.installation_items:
            if item_data.get("is_selected") and "func" in item_data:
                ordered_commands.append(item_data["func"])
        return ordered_commands
