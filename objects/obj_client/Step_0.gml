switch(state) {
    case "searching":
        // Look for any Boudoir in the room
        target_room = instance_nearest(x, y, obj_boudoir);
        
        if (target_room != noone) {
            state = "moving";
        }
        break;

    case "moving":
        // Move towards the target room
        var dir = point_direction(x, y, target_room.x, target_room.y);
        hspeed = lengthdir_x(move_speed, dir) ;
        vspeed = lengthdir_y(move_speed, dir);

        // Check if we have arrived (close enough to the room)
        if (point_distance(x, y, target_room.x, target_room.y) < 5) {
            hspeed = 0;
            vspeed = 0;
            state = "paying";
            alarm[0] = 60; // Wait 1 second (60 frames) before paying
        }
        break;

    case "paying":
        // We just wait for the alarm to finish
        break;
}
