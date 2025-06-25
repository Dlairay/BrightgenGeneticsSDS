import os 
import sys  
# --- Debugging Path and Import ---
print("\n--- Path and Import Debugging ---")
current_script_path = os.path.abspath(__file__)
current_script_dir = os.path.dirname(current_script_path)
print(f"DEBUG: Current script path: {current_script_path}")
print(f"DEBUG: Current script directory: {current_script_dir}")

# Assuming 'agent.py' (or 'testagent.py') is in 'backend/planner_agent'
# We need to add 'backend' to sys.path to import 'config.py' from 'backend'
# backend_dir should be '/Users/ray/Desktop/sds/backend'
backend_dir = os.path.dirname(current_script_dir) 
print(f"DEBUG: Calculated backend_dir: {backend_dir}")

# Add backend_dir to sys.path if it's not already there
if backend_dir not in sys.path:
    sys.path.insert(0, backend_dir)
print(f"DEBUG: sys.path after modification: {sys.path}")

# --- Attempt to import config.py ---
DATA_DIR = None # Initialize to None
try:
    import config
    DATA_DIR = config.DATA_DIR # Use DATA_DIR from config.py
    print("DEBUG: Successfully imported config.py.")
    print(f"DEBUG: DATA_DIR from config.py: {DATA_DIR}")
except ImportError as e:
    print(f"ERROR: Could not import config.py. Reason: {e}")
    print("ERROR: Please ensure 'config.py' exists in the 'backend' directory and has no syntax errors.")
    print("ERROR: Falling back to a hardcoded DATA_DIR for testing purposes. This might cause incorrect file paths.")
    # Fallback to a DATA_DIR that *might* work if config.py import fails
    # This assumes 'data' is a sibling of 'planner_agent' within 'backend'
    DATA_DIR = os.path.join(backend_dir, 'data') 
    print(f"DEBUG: Fallback DATA_DIR set to: {DATA_DIR}")
except AttributeError:
    print("ERROR: config.py was imported, but it does not define 'DATA_DIR'.")
    print("ERROR: Please ensure 'DATA_DIR' is defined in your 'config.py'.")
    print("ERROR: Falling back to a hardcoded DATA_DIR for testing purposes. This might cause incorrect file paths.")
    DATA_DIR = os.path.join(backend_dir, 'data')
    print(f"DEBUG: Fallback DATA_DIR set to: {DATA_DIR}")

# Final check for DATA_DIR
if DATA_DIR is None:
    print("CRITICAL ERROR: DATA_DIR could not be determined. Exiting.")
    sys.exit(1) # Exit if DATA_DIR is still None

print(f"DEBUG: Final DATA_DIR used: {DATA_DIR}")
print("----------------------------------\n")
