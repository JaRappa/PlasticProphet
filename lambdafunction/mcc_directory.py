import json
import os

# Global variable to hold MCC data
mcc_data = []


def load_mcc_directory():
    """
    Load MCC codes from the mcc_codes.json file.
    Called once on Lambda cold start.
    """
    global mcc_data
    
    if mcc_data:  # Already loaded
        return
    
    try:
        # Get the directory of this file
        current_dir = os.path.dirname(os.path.abspath(__file__))
        file_path = os.path.join(current_dir, 'data', 'mcc_codes.json')
        
        with open(file_path, 'r') as f:
            mcc_data = json.load(f)
        
        print(f"✅ Loaded {len(mcc_data)} MCC records from mcc_codes.json")
    
    except FileNotFoundError:
        print(f"❌ MCC codes file not found at {file_path}")
        mcc_data = []
    except json.JSONDecodeError as e:
        print(f"❌ Error parsing MCC codes JSON: {e}")
        mcc_data = []


def get_mcc_info_by_code(mcc):
    """
    Get MCC record by code.
    
    Args:
        mcc (str): MCC code
    
    Returns:
        dict or None: MCC record if found, None otherwise
    """
    if mcc is None:
        return None
    
    for record in mcc_data:
        if record.get('mcc') == mcc:
            return record
    
    return None


def find_mcc_for_merchant_name(generalized_name):
    """
    Find MCC code and category key for a generalized merchant name.
    
    Args:
        generalized_name (str): Normalized merchant name
    
    Returns:
        dict: {
            'mcc': str or None,
            'categoryKey': str or None
        }
    """
    if not generalized_name:
        return {'mcc': None, 'categoryKey': None}
    
    key = generalized_name.upper().strip()
    
    # Search through MCC records
    for record in mcc_data:
        edited_desc = (record.get('edited_description') or '').upper().strip()
        combined_desc = (record.get('combined_description') or '').upper().strip()
        
        if not edited_desc and not combined_desc:
            continue
        
        # Exact match
        if edited_desc == key or combined_desc == key:
            category_key = record.get('irs_description') or record.get('usda_description')
            return {
                'mcc': record.get('mcc'),
                'categoryKey': category_key
            }
        
        # Partial match (either description contains key or key contains description)
        if edited_desc and (key in edited_desc or edited_desc in key):
            category_key = record.get('irs_description') or record.get('usda_description')
            return {
                'mcc': record.get('mcc'),
                'categoryKey': category_key
            }
        
        if combined_desc and (key in combined_desc or combined_desc in key):
            category_key = record.get('irs_description') or record.get('usda_description')
            return {
                'mcc': record.get('mcc'),
                'categoryKey': category_key
            }
    
    # No match found
    return {'mcc': None, 'categoryKey': None}
