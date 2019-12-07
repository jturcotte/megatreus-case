// -*- mode: c -*-
/* All distances are in mm. */

/* set output quality */
$fn = 50;

/* Distance between key centers. */
column_spacing   = 19;
row_spacing      = column_spacing;

/* This number should exceed row_spacing and column_spacing. The
 default gives a 1mm = (20mm - 19mm) gap between keycaps and cuts in
 the top plate.*/
key_hole_size = 20;

/* rotation angle; the angle between the halves is twice this
   number */
angle = 10;

/* The radius of screw holes. Holes will be slightly bigger due
   to the cut width. */
screw_hole_radius = 1.5;
/* Each screw hole is a hole in a "washer". How big these "washers"
   should be depends on the material used: this parameter and the
   `switch_hole_size` determine the spacer wall thickness. */
washer_radius     = 4 * screw_hole_radius;

/* This constant allows tweaking the location of the screw holes near
   the USB cable. Only useful with small `angle` values. Try the value
   of 10 with angle=0. */
back_screw_hole_offset = 0;

/* Distance between halves. */
hand_separation        = 22.5;

/* The approximate size of switch holes. Used to determine how
   thick walls can be, i.e. how much room around each switch hole to
   leave. See spacer(). */
switch_hole_size = 14;

/* Sets whether the case should use notched holes. As far as I can
   tell these notches are not all that useful... */
use_notched_holes = true;

/* Number of rows and columns in the matrix. You need to update
   staggering_offsets if you change n_cols. */
n_rows = 5;
n_cols = 6;

/* Number of thumb keys (per hand), try 1 or 2. */
n_thumb_keys = 1;

/* The width of the USB cable hole in the spacer. */
cable_hole_width = 12;

/* Vertical column staggering offsets. The first element should
   be zero. */
staggering_offsets = [0, 4, 9, 5, -4, -4];

/* Whether or not to split the spacer into quarters. */
quarter_spacer = false;

/* Where the top/bottom split of a quartered spacer will be. */
spacer_quartering_offset = 60;

module rz(angle, center=undef) {
  /* Rotate children `angle` degrees around `center`. */
  translate(center) {
    rotate(angle) {
      translate(-center) {
        for (i=[0:$children-1])
          children(i);
      }
    }
  }
}

/* Compute coordinates of a point obtained by rotating p angle degrees
   around center. Used to compute locations of screw holes near the
   USB cable hole. */
function rz_fun(p, angle, center) = [cos(angle) * (p[0] - center[0]) - sin(angle) * (p[1] - center[1]) + center[0],
                                     sin(angle) * (p[0] - center[0]) + cos(angle) * (p[1] - center[1])+ center[1]];

module switch_hole(position, notches=use_notched_holes) {
  /* Cherry MX switch hole with the center at `position`. Sizes come
     from the ErgoDox design. */
  hole_size    = 13.97;
  notch_width  = 3.5001;
  notch_offset = 4.2545;
  notch_depth  = 0.8128;
  translate(position) {
    union() {
        translate([0,0,-1])
      cube([hole_size, hole_size,50], center=true);
      if (notches == true) {
        translate([0, notch_offset,-1]) {
          cube([hole_size+2*notch_depth, notch_width,50], center=true);
        }
        translate([0, -notch_offset,-1]) {
          cube([hole_size+2*notch_depth, notch_width,50], center=true);
        }
      }
    }
  }
};

module keycap_hole(position, size, ratio = [1, 1]) {
  /* Create a hole for a regular key. */
  translate(position) {
    w = size + column_spacing * (ratio[0] - 1);
    h = size + column_spacing * (ratio[1] - 1);
    cube([w, h, 50], center=true);
  }
}

module key(position, switch_holes, key_size=key_hole_size, ratio = [1, 1]) {
  if (switch_holes == true) {
    switch_hole(position);
  } else {
    keycap_hole(position, key_size, ratio);
  }
}

module regular_key (position, switch_holes, key_size=key_hole_size) {
  key(position, switch_holes, key_size);
}

module thumb_key (position, switch_holes, key_size=key_hole_size) {
  key(position, switch_holes, key_size, [1, 1.5]);
}

module space_bar (position, switch_holes, key_size=key_hole_size) {
  key(position, switch_holes, key_size, [2, 1]);
}

module outside_key (position, switch_holes, key_size=key_hole_size) {
  key(position, switch_holes, key_size, [1.5, 1]);
}

module column (bottom_position, switch_holes, key_size=key_hole_size, n_rows_adj=0) {
  /* Create a column of keys. */
  translate(bottom_position) {
    for (i = [0:(n_rows+n_rows_adj-1)]) {
      regular_key([0, i*column_spacing,-1], switch_holes, key_size);
    }
  }
}

module rotate_half() {
  /* Rotate the right half of the keys around the top left corner of
     the thumb key. Assumes that the thumb key is a 1x1.5 key and that
     it is shifted 0.5*column_spacing up relative to the nearest column. */
  rotation_y_offset = 1.75 * column_spacing;
  for (i=[0:$children-1]) {
    rz(angle, [hand_separation, rotation_y_offset]) {
      children(i);
    }
  }
}

module add_hand_separation() {
  /* Shift everything right to get desired hand separation. */
  for (i=[0:$children-1]) {
    translate([0.5*hand_separation, /* we get back the full separation
                                       because of mirroring */
               0]) children(i);
  }
}

module right_half (switch_holes=true, key_size=key_hole_size, really_right_half=true) {
  /* Create switch holes or key holes for the right half of the
     keyboard. Different key_sizes are used in top_plate() and
     spacer(). */
  x_offset = 0.5 * row_spacing;
  y_offset = 0.5 * column_spacing;
  thumb_key_offset = y_offset + 1.25 * column_spacing + staggering_offsets[0];
  arrow_key_offset = y_offset;

  rotate_half() {
    add_hand_separation() {
      // 2x 1.5u keys
      for (j=[0:1]) {
        thumb_key([x_offset, thumb_key_offset + j * 1.5 * column_spacing,-1], switch_holes, key_size);
      }
      // 1u keys above for the inside
      for (j=[0:0]) {
        regular_key([x_offset, thumb_key_offset + j * 1 * column_spacing + 2.75 * column_spacing,-1], switch_holes, key_size);
      }

      thum_keys_y = staggering_offsets[3] - 0.5*column_spacing;//+staggering_offsets[4]/2;

      if (really_right_half) {
        // Space bar
        space_bar([x_offset + (0.5+n_thumb_keys)*row_spacing, y_offset + thum_keys_y,-1], switch_holes, key_size);
        // Up arrow
        regular_key([x_offset + (3+n_thumb_keys)*row_spacing, y_offset + staggering_offsets[3],-1], switch_holes, key_size);
        // Down arrow
        regular_key([x_offset + (3+n_thumb_keys)*row_spacing, y_offset + staggering_offsets[3] - column_spacing,-1], switch_holes, key_size);
        // Left arrow
        regular_key([x_offset + (2+n_thumb_keys)*row_spacing, y_offset + staggering_offsets[3] - 0.5*column_spacing,-1], switch_holes, key_size);
        // Right arrow
        regular_key([x_offset + (4+n_thumb_keys)*row_spacing, y_offset + staggering_offsets[3] - 0.5*column_spacing,-1], switch_holes, key_size);
        // AltGr/Fn
        regular_key([x_offset + (5+n_thumb_keys)*row_spacing, y_offset + staggering_offsets[3] - 0.5*column_spacing,-1], switch_holes, key_size);

        // Normal keys
        // One less key, and offset up by one key.
        for (j=[0:(n_cols-2)]) {
          column([x_offset + (j+n_thumb_keys)*row_spacing, y_offset + column_spacing + staggering_offsets[j]], switch_holes, key_size, -1);
        }
      } else {
        // Normal keys
        // One less key, and offset up by one key.
        for (j=[0:4]) {
          column([x_offset + (j+n_thumb_keys)*row_spacing, y_offset + column_spacing + staggering_offsets[j]], switch_holes, key_size, -1);
        }
        // Move the left out keys a bit lower for easier thumb access
        regular_key([x_offset + (0+n_thumb_keys)*row_spacing, y_offset + thum_keys_y,-1], switch_holes, key_size);
        regular_key([x_offset + (1+n_thumb_keys)*row_spacing, y_offset + thum_keys_y,-1], switch_holes, key_size);
        // 1.25u and 1.75u keys in the middle
        key([x_offset + (2+n_thumb_keys+0.125)*row_spacing, y_offset + thum_keys_y,-1], switch_holes, key_size, [1.25, 1]);
        key([x_offset + (4+n_thumb_keys-0.375)*row_spacing, y_offset + thum_keys_y,-1], switch_holes, key_size, [1.75, 1]);

        // Outside column
        // Bottom 1.5u
        outside_key([
            x_offset + 0.25*row_spacing + (n_cols-1+n_thumb_keys)*row_spacing,
            y_offset + thum_keys_y,-1
          ], switch_holes, key_size);
      }

      // Outside column
      // Middle 1.5u
      for (i = [1:(n_rows-2)]) {
        outside_key([
            x_offset + 0.25*row_spacing + (n_cols-1+n_thumb_keys)*row_spacing,
            y_offset + staggering_offsets[n_cols - 1] + i*column_spacing,-1
          ], switch_holes, key_size);
      }
      // Top 1u
      regular_key([
          x_offset + (n_cols-1+n_thumb_keys)*row_spacing,
          y_offset + staggering_offsets[n_cols - 1] + (n_rows-1)*column_spacing,-1
        ], switch_holes, key_size);
    }
  }
}

module screw_hole(radius, offset_radius, position, direction) {
  /* Create a screw hole of radius `radius` at a location
     `offset_radius` from `position`, (diagonally), in the direction
     `direction`. Oh, what a mess this is. */
  /* direction is the 2-element vector specifying to which side of
     position to move to, [-1, -1] for bottom left, etc. */

  /* radius_offset is the offset in the x (or y) direction so that
     we're offset_radius from position */
  radius_offset = offset_radius / sqrt(2);
  /* key_hole_offset if the difference between key spacing and key
     hole edge */
  key_hole_offset = 0.5*(row_spacing - key_hole_size);
  x = position[0] + (radius_offset - key_hole_offset) * direction[0];
  y = position[1] + (radius_offset - key_hole_offset) * direction[1];
  translate([x,y,0]) {
    cylinder(r1=radius,r2=radius,h=3);
  }
}

module right_screw_holes(hole_radius) {
  right_x = (n_cols+n_thumb_keys+0.5)*row_spacing;
  /* coordinates of the back right screw hole before rotation... */
  back_right = [right_x,
               staggering_offsets[n_cols-1] + (n_rows+0.5) * column_spacing];
  // front_right = [(n_cols+n_thumb_keys+0.25)*row_spacing, staggering_offsets[n_cols-1]];
  front_center = [0.5*row_spacing, -0.25 * column_spacing];

  /* and after */
  tmp = rz_fun(back_right, angle, [0, 1.75*column_spacing]);
  tmp_front = rz_fun(front_center, angle, [0, 1.75*column_spacing]);

  // translate([0, 1.75*column_spacing])
  //     cube([5, 5,5]);
  // add_hand_separation()
  //   translate([tmp_front[0], 0])
  //     screw_hole(hole_radius, washer_radius,
  //            [0, 0],
  //            [0, 0]);

  // Front right hole calculated according to front_center
  rotate_half() {
    add_hand_separation() {
      // tmp_yo = rz_fun(front_right, -angle, front_center);


      // FIXME: Put this madness into a function
      x = right_x;
      y = front_center[1] + (x - front_center[0]) * tan(-angle);
      screw_hole(hole_radius, washer_radius,
             [x, y],
             [0, -0]);
//      cube(concat([x, y], 12), center=true);
    }
}
  // 0 = 0.75;

  rotate_half() {
    add_hand_separation() {
      // Back center
      // screw_hole(hole_radius, washer_radius,
      //            [row_spacing*0.75, staggering_offsets[n_cols-1] + (n_rows) * column_spacing],
      //            [-0, 0]);
      // Front center
      screw_hole(hole_radius, washer_radius,
                 front_center,
                 [0, -0]);
      // Front right
      // screw_hole(hole_radius, washer_radius,
      //             // FIXME: Proper maths
      //            front_right,
      //            [0, -0]);
      // Back right
      screw_hole(hole_radius, washer_radius,
                 back_right,
                 [0, 0]);
    }
  }

  // translate([washer_radius - tmp[0],

  // Opposite front left
  // mirror ([1,0,0]) {
  //   rotate_half() {
  //     add_hand_separation() {
  //     screw_hole(hole_radius, washer_radius,
  //                [row_spacing*0.75, staggering_offsets[n_cols-1] + (n_rows) * column_spacing],
  //                [-nudge, nudge]);
  //     screw_hole(hole_radius, washer_radius,
  //                [row_spacing, 0],
  //                [-nudge, -nudge]);
  //     }
  //   }
  // }

  // translate([ - tmp_front[0],
  // // translate([washer_radius - back_right.x,
  //            0]) {
  //   rotate_half() {
  //     add_hand_separation() {
  //       screw_hole(hole_radius, washer_radius,
  //         // FIXME: Move zero at the middle of the thumb key maybe instead?
  //         // Or just take back_right and translate by the divide x by 2...
  //                  front_right,
  //                  [nudge, 0]);
  //     }
  //   }
  // }

  /* add the screw hole near the cable hole */
  translate([washer_radius - tmp[0],
  // translate([washer_radius - back_right.x,
             back_screw_hole_offset]) {
    rotate_half() {
      add_hand_separation() {
        screw_hole(hole_radius, washer_radius,
          // FIXME: Move zero at the middle of the thumb key maybe instead?
          // Or just take back_right and translate by the divide x by 2...
                   back_right,
                   [0, 0]);
      }
    }
  }
}

module screw_holes_hull(hole_radius) {
  /* Create all the screw holes. */
  union() {
    hull() { right_screw_holes(hole_radius); }
    hull() { mirror ([1,0,0]) { right_screw_holes(hole_radius); } }
  }
}

module screw_holes(hole_radius) {
  /* Create all the screw holes. */
  union() {
    right_screw_holes(hole_radius);
    mirror ([1,0,0]) { right_screw_holes(hole_radius); }
  }
}

module left_half(switch_holes=true, key_size=key_hole_size) {
  mirror ([1,0,0]) { right_half(switch_holes, key_size, false); }
}

module extendZ() {
  translate([0,0,-0.05]) scale([1,1,1.1])
    for (i=[0:$children-1])
    children(i);
}

module bottom_plate(washer_radius_ratio=1.0) {
  color("Gainsboro")
  /* bottom layer of the case */
  difference() {
    hull() { screw_holes(washer_radius*washer_radius_ratio); }
    //screw_holes_hull(washer_radius);
    extendZ() screw_holes(screw_hole_radius);
  }
}

module top_plate(washer_radius_ratio=1.0) {
  /* top layer of the case */
  difference() {
    bottom_plate(washer_radius_ratio);
    right_half(false);
    left_half(false);
  }
}

module switch_plate() {
  /* the switch plate */
  difference() {
    bottom_plate();
    right_half();
    left_half();
  }
}

module spacer() {
  /* Create a spacer. */
  difference() {
    union() {
      difference() {
        bottom_plate();
        hull() {
          right_half(switch_holes=false, key_size=switch_hole_size + 3);
          left_half(switch_holes=false, key_size=switch_hole_size + 3);
        }
        
        //hull() right_half(switch_holes=false, key_size=switch_hole_size + 3);
        //hull() left_half(switch_holes=false, key_size=switch_hole_size + 3);
        
    /* add the USB cable hole: */
    translate([-0.5*cable_hole_width, 2*column_spacing,-1]) {
      cube([cable_hole_width, (2*n_rows) * column_spacing,50]);
    }
      }
      screw_holes(washer_radius);
    }
    extendZ() screw_holes(screw_hole_radius);
  }
}

module spacer_quadrant(spacer_quadrant_number) {
  /* Cut a quarter of a spacer. */
  translate([0, spacer_quartering_offset]) {
    intersection() {
      translate([0, -spacer_quartering_offset]) { spacer(); }
      rotate([0, 0, spacer_quadrant_number * 90]) { cube([1000, 1000,3]); }
    }
  }
}

module quartered_spacer()
{
  /* Assemble all four quarters of a spacer. */
  spacer_quadrant(0);
  spacer_quadrant(1);
  translate([-5,-10]) spacer_quadrant(2);
  translate([5,-10]) spacer_quadrant(3);
}

/* Create all four layers. */

// FIXME: Should rather be a ratio relative to 3mm, maybe also make a constant?
translate([0,0,12]) top_plate(2/3);
translate([0,0,9]) top_plate();
// projection(cut = false) 
  color("DimGray") translate([0, 0, 6]) { switch_plate(); }
translate([350, 0,0]) { bottom_plate(); }
translate([0,0,3]) spacer();
translate([0, 0,0]) {
  if (quarter_spacer == true) {
    quartered_spacer();
  }
  else {
    spacer();
  }
}
