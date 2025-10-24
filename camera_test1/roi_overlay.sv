

module roi_overlay (
    input  logic [9:0]  x_count,
    input  logic [8:0]  y_count,
    input  logic [11:0] video_in,
    output logic [11:0] video_out
);
    localparam int ROI_X_MIN = 310;
    localparam int ROI_X_MAX = 330;
    localparam int ROI_Y_MIN = 230;
    localparam int ROI_Y_MAX = 250;
    localparam int BORDER = 1;

    logic roi_border;
    assign roi_border =
        ((x_count >= ROI_X_MIN && x_count <= ROI_X_MAX) &&
         ((y_count >= ROI_Y_MIN && y_count <= ROI_Y_MIN + BORDER) || 
          (y_count >= ROI_Y_MAX - BORDER && y_count <= ROI_Y_MAX))) ||
        ((y_count >= ROI_Y_MIN && y_count <= ROI_Y_MAX) &&
         ((x_count >= ROI_X_MIN && x_count <= ROI_X_MIN + BORDER) || 
          (x_count >= ROI_X_MAX - BORDER && x_count <= ROI_X_MAX)));

    assign video_out = roi_border ? 12'hFFF : video_in;
endmodule

