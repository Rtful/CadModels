radius = 100;// Approximate radius of lampshade body.
height = 200;// Height of the lamp body
layers = 7; // Number of layers
cells_per_layer = 7; // Number of cells per layer

// Ratio of lump in cell. Ratio: 1/socket_ratio
cell_lump_height_ratio = 6;
// Depth of the lumpos. r/cell_lump_depth_ratio
cell_lump_depth_ratio = 10;

bholediameter = 50;// Hole in the bottom to mount the lamp:
bholeheight = 0.8;// For vase mode, set bholeheight to the same setting as the bottom layer.

// Height-ratio of socket to shade. Ratio: 1/socket_ratio
socket_ratio = layers;
socket_angle = 45;

//---------------------------- internal stuff below, change at your own risk ----------------------------//

cell_angle = 360 / (cells_per_layer / 2); // Degrees by which each cell is rotated, relative to the last one of its type
cell_width = radius * tan(cell_angle / 4);
cell_depth = -10; // Depth of the polyhedron (but only the cuboid part, without the dent)
cell_height = height / layers;
cell_lump_height = cell_height / cell_lump_height_ratio;
cell_lump_depth = radius / cell_lump_depth_ratio;

// Stuff for the n-gon that fills the interior of the model
cylinder_rotation = (cells_per_layer % 4 == 0) ?
    (360 / cells_per_layer / 2) :
        ((cells_per_layer % 4 == 2) ? 0 : -90);

inner_cylinder_radius = (radius + cell_depth) / cos(180 / cells_per_layer);
outer_cylinder_radius = (radius + cell_lump_depth - cell_depth) / cos(180 / cells_per_layer);

// Stuff for the slanted top where shade and socket come together
cone_height = (height - height / socket_ratio) + radius / cos(180 / cells_per_layer) * tan(socket_angle);
cone_radius = cone_height / tan(socket_angle);

// Coordinates of vertices that describe the polyhedron with the outward facing lump
p1 = [
        [cell_width, 0, 0], //0
        [-cell_width, 0, 0], //1
        [-cell_width, 0, cell_height], //2
        [cell_width, 0, cell_height], //3
        [0, -cell_lump_depth, cell_lump_height], //4
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
        [0, cell_lump_depth, cell_height - cell_lump_height], //4
        [cell_width, cell_depth, 0], //5
        [-cell_width, cell_depth, 0], //6
        [-cell_width, cell_depth, cell_height], //7
        [cell_width, cell_depth, cell_height], //8
    ];

// Vertices that the faces should connect
faces = [
        [4, 2, 1],
        [4, 3, 2],
        [3, 4, 0],
        [4, 1, 0],
        [1, 6, 5, 0],
        [2, 7, 6, 1],
        [8, 7, 2, 3],
        [5, 8, 3, 0],
        [5, 6, 7, 8]
    ];

module placeCell(rotation, vertices, height) {
    translate([sin(rotation) * radius, cos(rotation) * radius, height]) {
        // Single segment
        rotate([0, 0, -rotation])
            polyhedron(vertices, faces, 4);
    }
}

module placeLayer(current_z) {
    for (i = [0:1:cells_per_layer]) {
        current_degree = ((360 / cells_per_layer) * i);

        // Every other iteration
        if (cells_per_layer % 2 == 0 && i % 2 != 0) {
            placeCell(current_degree, p1, current_z);
        } else {
            placeCell(current_degree, p2, current_z);
        }
    }
}

module wholeShade() {
    translate([0, 0, height])
        rotate([180, 0, 0])
            union() {
                rotate([0, 0, cylinder_rotation])
                    cylinder(r = inner_cylinder_radius, h = height, $fn = cells_per_layer);

                for (i = [0:1:layers - 1]) {
                    current_z = i * cell_height;
                    // Every other iteration
                    if (i % 2 == 0) {
                        rotate([0, 0, cell_angle / 2])
                            placeLayer(current_z);
                    } else {
                        placeLayer(current_z);
                    }
                }
            }
}

module getNegative() {
    rotate([0, 0, cylinder_rotation - 180])
        intersection() {
            cylinder(r = outer_cylinder_radius, h = height * (9 / 10), $fn = cells_per_layer);
            cylinder(h = cone_height, r1 = cone_radius, r2 = 0, $fn = cells_per_layer);
        }
}

module shadeForSocket() {
    intersection() {
        wholeShade();
        getNegative();
    }
}

module socketForShade() {
    difference() {
        wholeShade();
        getNegative();
        cylinder(h = height, d = bholediameter);
    }
}

socketForShade();