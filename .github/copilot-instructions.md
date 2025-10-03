# Copilot Instructions for D-Bus Bluetooth Tracker

## Project Overview
This is a Home Assistant custom component that implements Bluetooth device tracking via D-Bus communication with BlueZ. The component has evolved from a legacy scanner-based approach to a modern entity-based device tracker.

## Architecture & Key Components

### Core Files Structure
- `custom_components/dbus_bt_tracker_v2/device_tracker.py` - Main platform setup and entity management
- `custom_components/dbus_bt_tracker_v2/bluetooth_tracker.py` - D-Bus communication and entity classes
- `custom_components/dbus_bt_tracker_v2/manifest.json` - Component metadata and dependencies

### Critical Architectural Patterns

#### 1. D-Bus Communication Pattern
The component uses `dbus-fast` for asynchronous D-Bus communication with BlueZ:
```python
# Always create/destroy bus connections for each scan cycle
bus = await MessageBus(bus_type=BusType.SYSTEM).connect()
try:
    # Perform operations
finally:
    bus.disconnect()
    await bus.wait_for_disconnect()
```

#### 2. BlueZ Device Path Convention
Device paths follow a specific pattern: `/org/bluez/{adapter}/dev_{mac_with_underscores}`
- Adapter path: `/org/bluez/hci0` 
- Device path: `/org/bluez/hci0/dev_AA_BB_CC_DD_EE_FF`

#### 3. Device State Management
Devices use a "last seen" timestamp approach rather than persistent connections:
- `update_state(is_reachable)` updates `_last_seen` timestamp
- `is_on` property checks if device was seen within `consider_home` interval
- Force updates enabled via `force_update = True`

### Home Assistant Integration Patterns

#### Entity vs Scanner Migration
The component has migrated from legacy scanner (`async_setup_scanner`) to modern entity-based approach (`async_setup_platform`):
```python
# CRITICAL: Tell legacy loader to stop
config['platform'].type = 'entity'
```

#### Device Discovery from known_devices.yaml
- Devices prefixed with `BT_` in `known_devices.yaml` are considered Bluetooth devices
- MAC addresses stripped of `BT_` prefix for D-Bus operations
- Only devices with `track: true` are monitored

#### Entity Registration Pattern
```python
tracked_entities = {mac: BluetoothDeviceEntity(mac, name, config) for mac, name in devices_to_track.items()}
async_add_entities(tracked_entities.values())
```

## Development Conventions

### Import Corrections for Home Assistant Compatibility
```python
# Corrected import for newer HA versions
from homeassistant.components.device_tracker.config_entry import TrackerEntity as DeviceTrackerEntity
```

### Error Handling for D-Bus Operations
- Always use timeouts with `asyncio.timeout()`
- Handle `MessageType.ERROR` responses, especially `AlreadyExists` errors
- Implement retry logic for `AlreadyExists` by disconnecting/reconnecting

### Logging Strategy
- Use module-level logger: `logger = logging.getLogger(__name__)`
- Debug-level logs for normal operations, warnings for missing scanners
- Include MAC addresses and adapter paths in debug messages

### Concurrency Management
- Use `asyncio.Lock()` to prevent overlapping scan operations
- Single D-Bus connection per scan cycle across all devices
- Async task creation for immediate first scan: `hass.async_create_task(update_bluetooth())`

## Configuration Schema
```yaml
device_tracker:
  - platform: dbus_bt_tracker_v2
    interval_seconds: 15
    consider_home: 90
    device_connect_timeout: 5
```

## Key Dependencies
- `dbus-fast>=1.87.0` for D-Bus communication
- Home Assistant's `bluetooth` integration for scanner discovery
- BlueZ with experimental features enabled (`--experimental` flag)

## Critical Gotchas
1. **Entity Setup Return**: Must return `None` (not `True`) from `async_setup_platform`
2. **Unique ID Pattern**: Use `f"bt_{mac.replace(':', '').lower()}"` for entity unique IDs
3. **D-Bus Paths**: Always replace colons with underscores in MAC addresses for device paths
4. **Legacy Migration**: Set `config['platform'].type = 'entity'` to prevent scanner conflicts

## Testing Workflow
- Devices must exist in `known_devices.yaml` with `BT_` prefix
- BlueZ service must be running with experimental features
- Test with `hass --debug` to see D-Bus communication logs