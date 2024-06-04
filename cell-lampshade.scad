// Wheter the model should be the socket, the lampshade or the whole model
modelType = 0; // 0=whole, 1=only shade, 2=only socket, 3=only socket with magnets

radius = 100;// Approximate radius of lampshade body.
height = 200;// Height of the lamp body
layers = 7; // Number of layers
cells_per_layer = 18; // Number of cells per layer

// Ratio of lump in cell. Ratio: 1/socket_ratio
cell_lump_height_ratio = 5;
// Depth of the lumpos. r/cell_lump_depth_ratio
cell_lump_depth_ratio = 10;

bholediameter = 80;// Hole in the bottom to mount the lamp:
bholeheight = 0.8;// For vase mode, set bholeheight to the same setting as the bottom layer.

// Height-ratio of socket to shade. Ratio: 1/socket_ratio
socket_ratio = layers;
socket_angle = 45;

// Magnet dimensions [lenth, width, thickness]
magnet = [19, 9, 1.7];

// Number of screws to fix the socket to the ceiling
screws = 4;

// Diameter of the screw in mm
screw_diameter = 5;

//---------------------------- internal stuff below, change at your own risk ----------------------------//

cell_angle = 360 / (cells_per_layer / 2); // Degrees by which each cell is rotated, relative to the last one of its type
cell_width = radius * tan(cell_angle / 4);
cell_height = height / layers;
cell_lump_height = cell_height / cell_lump_height_ratio;
cell_lump_depth = radius / cell_lump_depth_ratio;
cell_depth = cell_lump_depth * 1.1;

// Stuff for the n-gon that fills the interior of the model
cylinder_rotation = (cells_per_layer % 4 == 0) ?
    (360 / cells_per_layer / 2) :
        ((cells_per_layer % 4 == 2) ? 0 : -90);
cylinder_height = cell_height * (layers - 1) + 0.5 * cell_height;

inner_cylinder_radius = calculateSideRadius(radius - cell_lump_depth);
outer_cylinder_radius = calculateSideRadius(radius + cell_lump_depth + cell_depth);

// Stuff for the slanted top where shade and socket come together
cone_height = (height - height / socket_ratio) + calculateSideRadius(radius) * tan(socket_angle);
cone_radius = cone_height / tan(socket_angle);

// Coordinates of vertices that describe the polyhedron with the outward facing lump
p1 = [
        [cell_width, 0, 0], //0
        [-cell_width, 0, 0], //1
        [-cell_width, 0, cell_height], //2
        [cell_width, 0, cell_height], //3
        [0, -cell_lump_depth, cell_lump_height], //4
        [cell_width, -cell_depth, 0], //5
        [-cell_width, -cell_depth, 0], //6
        [-cell_width, -cell_depth, cell_height], //7
        [cell_width, -cell_depth, cell_height], //8
    ];

// Coordinates of vertices that describe the polyhedron with the inward facing lump
p2 = [
        [cell_width, 0, 0], //0
        [-cell_width, 0, 0], //1
        [-cell_width, 0, cell_height], //2
        [cell_width, 0, cell_height], //3
        [0, cell_lump_depth, cell_height - cell_lump_height], //4
        [cell_width, -cell_depth, 0], //5
        [-cell_width, -cell_depth, 0], //6
        [-cell_width, -cell_depth, cell_height], //7
        [cell_width, -cell_depth, cell_height], //8
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

module placeCell(rotation, vertices, z_position) {
    translate([sin(rotation) * radius, cos(rotation) * radius, z_position]) {
        // Single segment
        rotate([0, 0, -rotation])
            polyhedron(vertices, faces, 4);
    }
}

function calculateSideRadius(corner_radius) = corner_radius / cos(360 / (2 * cells_per_layer));

// This module has to be heavily customized
module placeMagnets() {
    trans_z = cylinder_height - cell_height / 7;
    magnet_angle = atan(cone_height / (cone_radius * cos(360 / (2 * cells_per_layer))));

    magnet_radius = (cone_height - trans_z) / tan(magnet_angle);

    rotate([0, 0, cylinder_rotation * 2])
        for (i = [0:1:cells_per_layer]) {
            rotation = 360 / cells_per_layer * i;

            trans_x = sin(rotation) * magnet_radius;
            trans_y = cos(rotation) * magnet_radius;

            translate([trans_x, trans_y, trans_z]) {
                rotate([-magnet_angle, 0, -rotation])
                    // The thickness is applied twice because half of it is hidden
                    cube(size = [magnet[0], magnet[1], 2 * magnet[2]], center = true);
            }
        }
}

module placeScrews() {
    bholeradius = bholediameter / 2;
    screw_radius = bholeradius + (inner_cylinder_radius - bholeradius) / 2;
    rotation = 360 / screws;
    for (i = [0:1:screws]) {
        rotate([0, 0, rotation * i]) {
            translate([screw_radius, 0, 0]) {
                cylinder(r = screw_diameter / 2, h = height, $fn = 100);
            }
        }
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
        union() {
            intersection() {
                cylinder(r = outer_cylinder_radius, h = cylinder_height, $fn = cells_per_layer);
                // Height-limiting cylinder
                cylinder(h = cone_height, r1 = cone_radius, r2 = 0, $fn = cells_per_layer); // Cone
            }
            translate([0, 0, -1])
                // Cylinder to also include the outwards lumps in the model
                cylinder(r = 2 * radius, h = cell_height * (layers - 1) + 1, $fn = cells_per_layer);
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
        cylinder(h = height, d = bholediameter, $fn = 100);
    }
}

module socketForShadeWithMagnets() {
    difference() {
        socketForShade();
        placeMagnets();
        placeScrews();
    }
}

if (modelType == 1) {
    shadeForSocket();
} else if (modelType == 2) {
    socketForShade();
} else if (modelType == 3) {
    socketForShadeWithMagnets();
} else {
    wholeShade();
}