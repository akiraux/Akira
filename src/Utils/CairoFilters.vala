/**
 * Copyright (c) 2021 Alecaddd (http://alecaddd.com)
 *
 * This file is part of Akira.
 *
 * Akira is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.

 * Akira is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.

 * You should have received a copy of the GNU General Public License
 * along with Akira. If not, see <https://www.gnu.org/licenses/>.
 *
 * Authored by: Martin "mbfraga" Fraga <mbfraga@gmail.com>
 */

public class Akira.Utils.CairoFilters : Object {

/*
 * The stack blur algorithm was invented by Mario Klingemann <mario@quasimondo.com>
 * http://incubator.quasimondo.com/processing/fast_blur_deluxe.php
 *
 * This version is taken from:
 * https://gitlab.gnome.org/Archive/lasem/-/blob/master/src/lsmsvgfiltersurface.c#L150
 * Compared to Mario's original source code, the lookup table is removed as the benefit
 * doesn't worth the memory usage in case of large radiuses. Also, the following code adds
 * alpha channel support and different radius for vertical and horizontal directions.
 */

    public static void stack_blur (Cairo.ImageSurface input, Cairo.ImageSurface output, int rx, int ry) {
        if (rx <= 0 && ry <= 0) {
            return;
        }

        unowned var input_pixels = (uint32[])input.get_data ();
        unowned var output_pixels = (uint32[])output.get_data ();
        var rowstride = input.get_stride ();

        int w = input.get_width ();
        int h = input.get_height ();

        if (output.get_width () != w || output.get_height () != h || output.get_stride () != rowstride) {
            assert (false);
            return;
        }

        uint32 p;
        int rsum,gsum,bsum,asum,x,y,i,yp;
        int routsum,goutsum,boutsum, aoutsum;
        int rinsum,ginsum,binsum, ainsum;

        int* sir;
        //unowned int[] sir;

        int yw = 0;
        int yi = 0;

        int wm = w - 1;
        int hm = h - 1;
        int wh = w * h;

        var r = new int[wh];
        var g = new int[wh];
        var b = new int[wh];
        var a = new int[wh];

        int stackpointer;
        int stackstart;
        int rbs;

        int sir_pos;

        int div = 2 * rx + 1;
        int divsum = (div + 1) >> 1;
        divsum = divsum * divsum;
        var stack = new int[div * 4];
        int r1 = rx + 1;

        var vmin = new int[w];
        for (y = 0; y < h; y++) {
            rinsum=ginsum=binsum=ainsum=routsum=goutsum=boutsum=aoutsum=rsum=gsum=bsum=asum=0;
            yi = y * rowstride / 4;

            for (i = -rx; i <= rx; i++) {
                p = input_pixels [yi + int.min (wm, int.max (i, 0))];
                //sir_pos = 4 * (i + rx);
                //sir = stack[sir_pos:sir_pos + 4];
                sir = &stack[4 * (i + rx)];
                sir[0] = (int)((p & 0x00ff0000)>>16);
                sir[1] = (int)((p & 0x0000ff00)>>8);
                sir[2] = (int)((p & 0x000000ff));
                sir[3] = (int)((p & 0xff0000ff)>>24);

                rbs= r1 - i.abs ();
                rsum+=sir[0]*rbs;
                gsum+=sir[1]*rbs;
                bsum+=sir[2]*rbs;
                asum+=sir[3]*rbs;

                if (i>0){
                    rinsum+=sir[0];
                    ginsum+=sir[1];
                    binsum+=sir[2];
                    ainsum+=sir[3];
                } else {
                    routsum+=sir[0];
                    goutsum+=sir[1];
                    boutsum+=sir[2];
                    aoutsum+=sir[3];
                }
            }
            stackpointer=rx;

            for (x = 0; x < w; x++){

                r[yi] = rsum / divsum;
                g[yi] = gsum / divsum;
                b[yi] = bsum / divsum;
                a[yi] = asum / divsum;
                rsum -= routsum;
                gsum -= goutsum;
                bsum -= boutsum;
                asum -= aoutsum;

                stackstart = stackpointer - rx + div;
                //sir_pos = 4 * (stackstart % div);
                //sir = stack [sir_pos:sir_pos + 4];
                sir = &stack [4 * (stackstart % div)];

                routsum -= sir[0];
                goutsum -= sir[1];
                boutsum -= sir[2];
                aoutsum -= sir[3];

                if (y == 0){
                    vmin[x] = int.min (x + rx + 1, wm);
                }

                p = input_pixels [yw + vmin[x]];

                sir[0] = (int)((p & 0x00ff0000)>>16);
                sir[1] = (int)((p & 0x0000ff00)>>8);
                sir[2] = (int)((p & 0x000000ff));
                sir[3] = (int)((p & 0xff000000)>>24);

                rinsum += sir[0];
                ginsum += sir[1];
                binsum += sir[2];
                ainsum += sir[3];

                rsum += rinsum;
                gsum += ginsum;
                bsum += binsum;
                asum += ainsum;

                stackpointer = (stackpointer + 1) % div;
                //sir_pos = 4 * (stackpointer % div);
                //sir = stack [sir_pos:sir_pos + 4];
                sir = &stack [4 * ((stackpointer) % div)];

                routsum += sir[0];
                goutsum += sir[1];
                boutsum += sir[2];
                aoutsum += sir[3];

                rinsum -= sir[0];
                ginsum -= sir[1];
                binsum -= sir[2];
                ainsum -= sir[3];

                yi++;
            }
            yw += w;
        }

        div = 2 * ry + 1;
        divsum = (div + 1) >> 1;
        divsum = divsum * divsum;

        stack = new int[div * 4];
        r1 = ry + 1;
        vmin = new int[h];

        for (x=0;x<w;x++){
            rinsum=ginsum=binsum=ainsum=routsum=goutsum=boutsum=aoutsum=rsum=gsum=bsum=asum=0;
            yp = -ry * w;
            for (i = -ry; i <= ry; i++){
                yi= int.max (0, yp) + x;

                //sir_pos = 4 * (i + ry);
                //sir = stack[sir_pos:sir_pos + 4];
                sir = &stack [4 * (i + ry)];

                sir[0] = r[yi];
                sir[1] = g[yi];
                sir[2] = b[yi];
                sir[3] = a[yi];

                rbs = r1 - i.abs ();

                rsum += r[yi] * rbs;
                gsum += g[yi] * rbs;
                bsum += b[yi] * rbs;
                asum += a[yi] * rbs;

                if (i>0){
                    rinsum += sir[0];
                    ginsum += sir[1];
                    binsum += sir[2];
                    ainsum += sir[3];
                } else {
                    routsum += sir[0];
                    goutsum += sir[1];
                    boutsum += sir[2];
                    aoutsum += sir[3];
                }

                if(i<hm){
                    yp+=w;
                }
            }

            yi=x;
            stackpointer=ry;

            for (y = 0; y < h; y++){
                output_pixels [yi] =
                    ((asum / divsum) << 24) |
                    ((rsum / divsum) << 16) |
                    ((gsum / divsum) << 8) |
                    (bsum / divsum);

                rsum -= routsum;
                gsum -= goutsum;
                bsum -= boutsum;
                asum -= aoutsum;

                stackstart = stackpointer - ry + div;
                //sir_pos = 4 * (stackstart % div);
                //sir = stack [sir_pos:sir_pos + 4];
                sir = &stack [4 * (stackstart % div)];

                routsum -= sir[0];
                goutsum -= sir[1];
                boutsum -= sir[2];
                aoutsum -= sir[3];

                if(x==0) {
                    vmin[y] = int.min (y + r1, hm) * w;
                }
                p = x + vmin[y];

                sir[0] = r[p];
                sir[1] = g[p];
                sir[2] = b[p];
                sir[3] = a[p];

                rinsum += sir[0];
                ginsum += sir[1];
                binsum += sir[2];
                ainsum += sir[3];

                rsum += rinsum;
                gsum += ginsum;
                bsum += binsum;
                asum += ainsum;

                stackpointer = (stackpointer + 1) % div;
                //sir_pos = 4 * stackpointer;
                //sir = stack [sir_pos:sir_pos + 4];
                sir = &stack[4 * stackpointer];

                routsum += sir[0];
                goutsum += sir[1];
                boutsum += sir[2];
                aoutsum += sir[3];

                rinsum -= sir[0];
                ginsum -= sir[1];
                binsum -= sir[2];
                ainsum -= sir[3];

                yi += rowstride / 4;
            }
        }
    }
}