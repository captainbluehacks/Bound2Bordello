hovered = noone;
selected = noone;

/// @description Get the currently selected instance.
/// @return {instance} The selected instance, or noone if nothing is selected.
function get_selection() {
	return selected;
}

// Not currently used, but I am considering highlighting rooms and characters you can select.
/// @description Get the instance currently under the hover state.
/// @return {instance} The hovered instance, or noone if nothing is hovered.
function get_hovered() {
	return hovered;
}