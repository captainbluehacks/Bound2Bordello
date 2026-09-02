/// @description Returns an array of keys from a ds_map
/// @param ds_map _map The map instance
///
/// @return array Keys
function scr_map_get_keys(_map){
    // Use array_keys which works for both arrays and maps
    return array_keys(_map);
}
