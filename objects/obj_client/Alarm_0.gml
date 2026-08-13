global.money += 50; // The client pays!
global.nightly_clients += 1;
show_debug_message("Client paid 50 dollars!");
instance_destroy(); // Client leaves the building