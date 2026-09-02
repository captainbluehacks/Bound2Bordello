/// @description Returns the display name for a resource key
/// @param string _resourceKey The internal resource key (e.g., "lust_mana")
///
/// @return string Display-friendly name (e.g., "Lust Mana")
function scr_resource_display_name(_resourceKey){
    switch(_resourceKey){
        case "value": return "Value";
        case "power": return "Power";
        case "stock": return "Stock";
        case "cash": return "Cash";
        case "lust_mana": return "Lust Mana";
        case "humiliation_mana": return "Humiliation Mana";
        case "fear_mana": return "Fear Mana";
        case "influence": return "Influence";
        // Add any other resource keys here
        default: return _resourceKey; // fallback to key itself
    }
}
