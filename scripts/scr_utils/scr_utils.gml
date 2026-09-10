/// @description Generates a unique client id.
function gen_client_id() {
    static counter = 0;
    counter++;
    return counter;
}
