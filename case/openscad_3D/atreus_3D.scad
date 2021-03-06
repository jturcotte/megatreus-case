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

top_most_plate_bezel = 1.5;
/* The radius of screw holes. Holes will be slightly bigger due
   to the cut width. */
screw_hole_radius = 1.5;
/* Each screw hole is a hole in a "washer". How big these "washers"
   should be depends on the material used: this parameter and the
   `switch_hole_size` determine the spacer wall thickness. */
washer_radius     = screw_hole_radius * 2 + top_most_plate_bezel + 1;

/* Distance between halves. */
hand_separation        = 23;

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
cable_hole_width = 21;

/* Vertical column staggering offsets. The first element should
   be zero. */
staggering_offsets = [0, 4, 9, 5, -4, -4];
thumb_keys_y = staggering_offsets[3] - 0.5*column_spacing;

/* Whether or not to split the spacer into quarters. */
quarter_spacer = false;

/* Where the top/bottom split of a quartered spacer will be. */
cable_hole_offset = -120;

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

module keycap_hole(position, size=key_hole_size, ratio = [1, 1]) {
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


      if (really_right_half) {
        // Space bar
        space_bar([x_offset + (0.5+n_thumb_keys)*row_spacing, y_offset + thumb_keys_y,-1], switch_holes, key_size);
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
        regular_key([x_offset + (0+n_thumb_keys)*row_spacing, y_offset + thumb_keys_y,-1], switch_holes, key_size);
        regular_key([x_offset + (1+n_thumb_keys)*row_spacing, y_offset + thumb_keys_y,-1], switch_holes, key_size);
        // 1.25u and 1.75u keys in the middle
        key([x_offset + (2+n_thumb_keys+0.125)*row_spacing, y_offset + thumb_keys_y,-1], switch_holes, key_size, [1.25, 1]);
        key([x_offset + (4+n_thumb_keys-0.375)*row_spacing, y_offset + thumb_keys_y,-1], switch_holes, key_size, [1.75, 1]);

        // Outside column
        // Bottom 1.5u
        outside_key([
            x_offset + 0.25*row_spacing + (n_cols-1+n_thumb_keys)*row_spacing,
            y_offset + thumb_keys_y,-1
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

module screw_hole(radius, position) {
  /* Create a screw hole of radius `radius` at a location `position`. */
  translate(position) {
    cylinder(r1=radius,r2=radius,h=3);
  }
}

function unrotate_align_right(ref_point, new_x) =
  [new_x, ref_point[1] + (new_x - ref_point[0]) * tan(-angle)];

function unrotate_align_left(ref_point, new_x) =
  [new_x, ref_point[1] - (new_x - ref_point[0]) * tan(angle)];

module right_screw_holes(hole_radius, washer_connector) {
  // Align the middle of some holes with the case's edge
  key_hole_gap_with_cap = (key_hole_size-row_spacing)/2.0;
  right_x = (n_cols+n_thumb_keys+0.5)*row_spacing + key_hole_gap_with_cap;
  back_center_x = (n_thumb_keys+1.5)*row_spacing;
  back_right = [right_x,
               staggering_offsets[n_cols-1] + (n_rows+0.55) * column_spacing];
  front_center = [0.5*row_spacing, thumb_keys_y + 0.5 * column_spacing];
  front_right = [right_x, -1.4 * column_spacing];

  rotate_half() {
    add_hand_separation() {
      // Front center
      screw_hole(hole_radius, front_center);
      if (washer_connector) {
        hull() {
          // Hard-code a bunch of factors that connect the washers with the spacer.
          screw_hole(hole_radius, front_center);
          screw_hole(hole_radius, front_center + [0.5*hole_radius, -1.5*hole_radius]);
          screw_hole(hole_radius, front_center + [-hole_radius, -1.25*hole_radius]);
        }
      } else {
        screw_hole(hole_radius, front_center);
      }
      // Back right
      screw_hole(hole_radius, back_right);

      // Front right
      screw_hole(hole_radius, front_right);
      // Back center
      screw_hole(hole_radius, unrotate_align_left(back_right, back_center_x));
    }
  }  
}

module screw_holes(hole_radius, washer_connector) {
  /* Create all the screw holes. */
  union() {
    right_screw_holes(hole_radius, washer_connector);
    mirror ([1,0,0]) { right_screw_holes(hole_radius, washer_connector); }
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

module base_plate(edge_gap=0.0) {
  color("Gainsboro")
  /* bottom layer of the case */
  difference() {
    hull() { screw_holes(washer_radius - edge_gap); }
    extendZ() screw_holes(screw_hole_radius);
  }
}

module top_plate(edge_gap=0.0) {
  /* top layer of the case */
  difference() {
    base_plate(edge_gap);
    right_half(false);
    left_half(false);
  }
  // translate([0.0, 0.0, 0.5]) color("white") screw_holes(3);
}

module switch_plate() {
  /* the switch plate */
  difference() {
    base_plate();
    right_half();
    left_half();
  }
}

module spacer() {
  /* Create a spacer. */
  difference() {
    union() {
      difference() {
        base_plate();
        hull() {
          right_half(switch_holes=false, key_size=switch_hole_size + 3);
          left_half(switch_holes=false, key_size=switch_hole_size + 3);

          // Leave some extra space for the micro-controller at the top.
          rotate_half() add_hand_separation() {
            keycap_hole([1.5*row_spacing, 5.75*column_spacing]);
            keycap_hole([(n_cols+0.75)*row_spacing, 4.5*column_spacing]);
          }
          mirror ([1,0,0]) rotate_half() add_hand_separation() {
            keycap_hole([1.5*row_spacing, 5.75*column_spacing]);
            keycap_hole([(n_cols+0.75)*row_spacing, 4.5*column_spacing]);
          }

        }

        /* add the USB cable hole: */
        translate([cable_hole_offset + cable_hole_width/2, 6*column_spacing,-1]) {
          cube([cable_hole_width, (n_rows) * column_spacing,50], center=true);
        }
      }
      screw_holes(washer_radius, washer_connector=true);
    }
    extendZ() screw_holes(screw_hole_radius);
  }
}

module bottom_plate() {
  hole_width = 70;
  difference() {
    base_plate();
    translate([-hole_width/2, n_rows * column_spacing + 2, -0.5])
      cube([hole_width, 500,4]);
  }
}

module spacer_quadrant(spacer_quadrant_number) {
  /* Cut a spacer. */
  hole_to_center = -cable_hole_offset - cable_hole_width/2;
  intersection() {
    spacer();
    translate([-hole_to_center + spacer_quadrant_number * 2 * hole_to_center, -500 ]) {
      cube([hole_to_center*2, 1000,3]);
    }
  }
}

module bottom_quadrant(left) {
  intersection() {
    bottom_plate();
    translate([0, -500]) {
      if (left)
        cube([1000, 1000,3]);
      else
        mirror([1,0,0]) cube([1000, 1000,3]);
    }
  }
}

module quartered_spacer()
{
  /* Assemble all three parts of a spacer. */
  translate([-10,0]) spacer_quadrant(-1);
  spacer_quadrant(0);
  translate([10,0]) spacer_quadrant(1);
}

module quartered_bottom()
{
  /* Assemble all three parts of a spacer. */
  translate([-10,0]) bottom_quadrant(false);
  translate([10,0]) bottom_quadrant(true);
}

/* Create all four layers. */
// Use an edge gap of half the plate's height.
translate([0,0,12]) top_plate(top_most_plate_bezel);
translate([0,0,9]) top_plate();
// projection(cut = false) 
color("DimGray") translate([0, 0, 6]) { switch_plate(); }

// translate([0,0,-3])
translate([370,0,0])
 {
  if (quarter_spacer == true) {
    quartered_bottom();
  }
  else {
    bottom_plate();
  }
}

translate([0,0,3]) spacer();

translate([0,0,0]) {
  if (quarter_spacer == true) {
    quartered_spacer();
  }
  else {
    spacer();
  }
}
