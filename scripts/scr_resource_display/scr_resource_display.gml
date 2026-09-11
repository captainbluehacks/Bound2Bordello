/// @description Returns the UI‑friendly name for a resource key
/// @param _resourceKey   e.g. "lust", "cash"
/// @return string
function scr_resource_display_name(_resourceKey){
    switch(_resourceKey){
        case "value"          : return "Value";
        case "power"          : return "Power";
        case "stock"          : return "Stock";
        case "cash"           : return "Cash";
        case "lust"      : return "Lust Mana";
        case "humiliation": return "Humiliation Mana";
        case "fear"       : return "Fear Mana";
        case "influence"      : return "Influence";
        // Add any new resources here
        default: return _resourceKey;   // fallback
    }
}
