radius = 50;// Approximate radius of lampshade body.
height = 200;// Height of the lamp body
layers = 7; // Number of layers
cells_per_layer = 4; // Number of cells per layer

// Ratio of lump in cell. Ratio: 1/socket_ratio
cell_lump_height_ratio = 6;
// Depth of the lumpos. r/cell_lump_depth_ratio
cell_lump_depth_ratio = 10;

bholediameter = 50;// Hole in the bottom to mount the lamp:
bholeheight = 0.8;// For vase mode, set bholeheight to the same setting as the bottom layer.

// Height-ratio of socket to shade. Ratio: 1/socket_ratio
socket_ratio = 7.3;

//---------------------------- internal stuff below, change at your own risk ----------------------------//

cell_angle = 360 / (cells_per_layer / 2); // Degrees by which each cell is rotated, relative to the last one of its type
cell_width = radius * tan(cell_angle / 4);
cell_depth = -10; // Depth of the polyhedron (but only the cuboid part, without the dent)
cell_height = height / layers;
cell_lump = cell_height / cell_lump_height_ratio;

cylinder_rotation = (cells_per_layer % 4 == 0) ?
    (360 / cells_per_layer / 2) :
        ((cells_per_layer % 4 == 2) ? 0 : -90);

cylinder_radius = (radius + cell_depth) / cos(180 / cells_per_layer);

// Stuff for the slanted top where shade and socket come together
//cone_radius = radius + ((socket_ratio - 1) * height / socket_ratio / tan(60));
cone_height = height / socket_ratio + tan(60) * (radius - height / socket_ratio / tan(60));

// Coordinates of vertices that describe the polyhedron with the outward facing lump
p1 = [
        [cell_width, 0, 0], //0
        [-cell_width, 0, 0], //1
        [-cell_width, 0, cell_height], //2
        [cell_width, 0, cell_height], //3
        [0, radius / cell_lump_depth_ratio, cell_lump], //4
        [cell_width, cell_depth, 0], //5
        [-cell_width, cell_depth, 0], //6
        [-cell_width, cell_depth, cell_height], //7
        [cell_width, cell_depth, cell_height], //8
    ];

// Coordinates of vertices that describe the polyhedron with the inward facing lump
p2 = [
        [cell_width, 0, 0], //0
        [-cell_width, 0, 0], //1
        [-cell_width, 0, cell_height], //2
        [cell_width, 0, cell_height], //3
        [0, -radius / cell_lump_depth_ratio, cell_height - cell_lump], //4
        [cell_width, cell_depth, 0], //5
        [-cell_width, cell_depth, 0], //6
        [-cell_width, cell_depth, cell_height], //7
        [cell_width, cell_depth, cell_height], //8
    ];

// Vertices that the faces should connect
faces = [
        [1, 2, 4],
        [2, 3, 4],
        [0, 4, 3],
        [0, 1, 4],
        [0, 5, 6, 1],
        [1, 6, 7, 2],
        [3, 2, 7, 8],
        [0, 3, 8, 5],
        [8, 7, 6, 5]
    ];

module placeCell(rotation, vertices, height) {
    translate([sin(rotation) * radius, cos(rotation) * radius, height]) {
        // Single segment
        rotate([0, 0, -rotation])
            polyhedron(vertices, faces, 4);
    }
}

module placeLayer(current_z, offset) {
    for (current_degree = [0:cell_angle / 2:360]) {

        // Every other iteration
        if ((current_degree / cell_angle) % 1 == 0) {
            placeCell(current_degree + offset, p1, current_z);
        } else {
            placeCell(current_degree + offset, p2, current_z);
        }
    }
}

module wholeShade() {
    translate([0, 0, height])
        rotate([180, 0, 0])
            union() {
                rotate([0, 0, cylinder_rotation])
                    cylinder(r = cylinder_radius, h = height, $fn = cells_per_layer);

                for (i = [0:1:layers - 1]) {
                    current_z = i * cell_height;
                    // Every other iteration
                    if (i % 2 == 0) {
                        placeLayer(current_z, cell_angle / 2);
                    } else {
                        placeLayer(current_z, 0);
                    }
                }
            }
}

module shadeForSocket() {
    intersection() {
        cylinder(h = cone_height, r1 = cone_radius, r2 = 0);
        intersection() {
            wholeShade();
            cylinder(r = radius * (11 / 10), h = height * (9 / 10));
        }
    }
}

module socketForShade() {
    difference() {
        wholeShade();
        shadeForSocket();
        cylinder(h = height, d = bholediameter);
    }
}


//cylinder(h = cone_height, r1 = cone_radius, r2 = 0);
//color("red") shadeForSocket();
//color("green") socketForShade();
wholeShade();

//polyhedron(p1, faces, 4);

//translate([0, 0, height - height / socket_ratio])
//    cylinder(h = cone_height, r1 = radius, r2 = 0, $fn = cells_per_layer);

//rotate([0, 0, cylinder_rotation])
//    cylinder(r = radius, h = height, $fn = cells_per_layer);
//placeLayer(0, 0);