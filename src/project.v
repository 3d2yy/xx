/*
 * TinyTapeout VGA - Moving Sine Wave
 *
 * Muestra una onda senoidal animada:
 *   - Fondo negro
 *   - Cuadrícula gris
 *   - Ejes blancos
 *   - Onda senoidal verde
 *
 * Requiere hvsync_generator.v
 */

`default_nettype none

module tt_um_3d2yy_moving_sine_wave(
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

    // ============================================================
    // VGA
    // ============================================================

    wire hsync;
    wire vsync;
    wire video_active;

    wire [9:0] pix_x;
    wire [9:0] pix_y;

    wire [1:0] R;
    wire [1:0] G;
    wire [1:0] B;


    // ============================================================
    // TinyVGA PMOD pin mapping
    // ============================================================

    assign uo_out = {
        hsync,
        B[0],
        G[0],
        R[0],
        vsync,
        B[1],
        G[1],
        R[1]
    };


    // No usamos los pines bidireccionales
    assign uio_out = 8'b00000000;
    assign uio_oe  = 8'b00000000;


    // ============================================================
    // VGA timing generator
    // ============================================================

    hvsync_generator hvsync_gen (
        .clk(clk),
        .reset(~rst_n),

        .hsync(hsync),
        .vsync(vsync),

        .display_on(video_active),

        .hpos(pix_x),
        .vpos(pix_y)
    );


    // ============================================================
    // CUADRÍCULA
    // ============================================================
    //
    // Una línea cada 32 píxeles.
    //
    // pix_x[4:0] cuenta:
    //
    // 0 ... 31
    //
    // y vuelve a cero.
    // ============================================================

    wire grid_x;
    wire grid_y;
    wire grid;

    assign grid_x = (pix_x[4:0] == 5'b00000);
    assign grid_y = (pix_y[4:0] == 5'b00000);

    assign grid = grid_x | grid_y;


    // ============================================================
    // EJES
    // ============================================================

    // Centro vertical de una pantalla 640x480:
    //
    // y = 240
    //
    // Eje vertical:
    //
    // x = 320

    wire axis_horizontal;
    wire axis_vertical;
    wire axes;

    assign axis_horizontal = (pix_y == 10'd240);
    assign axis_vertical   = (pix_x == 10'd320);

    assign axes = axis_horizontal | axis_vertical;


    // ============================================================
    // ANIMACIÓN
    // ============================================================
    //
    // phase determina cuánto desplazamos la onda.
    //
    // Tiene 5 bits:
    //
    // 0 ... 31
    //
    // porque nuestra tabla seno tiene 32 muestras.
    // ============================================================

    reg [4:0] phase;

    /*
     * No utilizamos vsync directamente como reloj.
     *
     * Detectamos su flanco usando el reloj principal.
     */

    reg vsync_previous;

    always @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            vsync_previous <= 1'b0;
            phase          <= 5'd0;

        end else begin

            vsync_previous <= vsync;

            // Flanco ascendente de VSYNC
            if (vsync && !vsync_previous) begin
                phase <= phase + 5'd2;
            end

        end
    end


    // ============================================================
    // ÍNDICE DE LA ONDA SENOIDAL
    // ============================================================
    //
    // pix_x >> 2:
    //
    // Cada valor de la tabla dura 4 píxeles.
    //
    // Como tenemos 32 valores:
    //
    // 32 × 4 = 128 píxeles por período.
    //
    // Aproximadamente tenemos:
    //
    // 640 / 128 = 5 ondas en pantalla.
    // ============================================================

    wire [4:0] sine_index;

    assign sine_index = pix_x[6:2] + phase;


    // ============================================================
    // SINE LOOKUP TABLE
    // ============================================================
    //
    // Esta es nuestra "función seno".
    //
    // Centro:
    //
    // y = 240
    //
    // Amplitud:
    //
    // aproximadamente 100 píxeles
    //
    // Por tanto:
    //
    // valor máximo:
    //      y ~= 140
    //
    // valor mínimo:
    //      y ~= 340
    //
    // Recuerda:
    //
    // VGA:
    //
    // y=0
    //  |
    //  v
    //
    // Por eso el pico positivo aparece ARRIBA.
    // ============================================================

    reg [9:0] sine_y;

    always @(*) begin

        case (sine_index)

            5'd0:  sine_y = 10'd240;
            5'd1:  sine_y = 10'd220;
            5'd2:  sine_y = 10'd202;
            5'd3:  sine_y = 10'd184;
            5'd4:  sine_y = 10'd169;
            5'd5:  sine_y = 10'd157;
            5'd6:  sine_y = 10'd148;
            5'd7:  sine_y = 10'd142;

            5'd8:  sine_y = 10'd140;

            5'd9:  sine_y = 10'd142;
            5'd10: sine_y = 10'd148;
            5'd11: sine_y = 10'd157;
            5'd12: sine_y = 10'd169;
            5'd13: sine_y = 10'd184;
            5'd14: sine_y = 10'd202;
            5'd15: sine_y = 10'd220;

            5'd16: sine_y = 10'd240;

            5'd17: sine_y = 10'd260;
            5'd18: sine_y = 10'd278;
            5'd19: sine_y = 10'd296;
            5'd20: sine_y = 10'd311;
            5'd21: sine_y = 10'd323;
            5'd22: sine_y = 10'd332;
            5'd23: sine_y = 10'd338;

            5'd24: sine_y = 10'd340;

            5'd25: sine_y = 10'd338;
            5'd26: sine_y = 10'd332;
            5'd27: sine_y = 10'd323;
            5'd28: sine_y = 10'd311;
            5'd29: sine_y = 10'd296;
            5'd30: sine_y = 10'd278;
            5'd31: sine_y = 10'd260;

            default:
                sine_y = 10'd240;

        endcase

    end


    // ============================================================
    // DIBUJAR LA ONDA
    // ============================================================
    //
    // Una línea de 5 píxeles:
    //
    // sine_y - 2
    // sine_y - 1
    // sine_y
    // sine_y + 1
    // sine_y + 2
    //
    // Esto hace que sea mucho más visible.
    // ============================================================

    wire sine_pixel;

    assign sine_pixel =
        (pix_y >= (sine_y - 10'd2)) &&
        (pix_y <= (sine_y + 10'd2));


    // ============================================================
    // RENDERER
    // ============================================================
    //
    // Prioridad:
    //
    // 1. Fuera del área VGA -> negro
    // 2. Seno              -> verde
    // 3. Ejes              -> blanco
    // 4. Cuadrícula        -> gris
    // 5. Fondo             -> negro
    //
    // Cada color tiene 2 bits:
    //
    // 00 = apagado
    // 01 = bajo
    // 10 = medio
    // 11 = máximo
    // ============================================================


    // ROJO

    assign R =
        !video_active ? 2'b00 :
        sine_pixel    ? 2'b00 :
        axes          ? 2'b11 :
        grid          ? 2'b01 :
                        2'b00;


    // VERDE

    assign G =
        !video_active ? 2'b00 :
        sine_pixel    ? 2'b11 :
        axes          ? 2'b11 :
        grid          ? 2'b01 :
                        2'b00;


    // AZUL

    assign B =
        !video_active ? 2'b00 :
        sine_pixel    ? 2'b00 :
        axes          ? 2'b11 :
        grid          ? 2'b01 :
                        2'b00;


    // ============================================================
    // UNUSED INPUTS
    // ============================================================

    wire _unused_ok;

    assign _unused_ok = &{
        ena,
        ui_in,
        uio_in
    };


endmodule

`default_nettype wire