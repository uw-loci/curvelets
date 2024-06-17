/*
 * Written for the Laboratory for Optical and Computational Instrumentation, UW-Madison
 *
 * Author: Matthew Dutson
 * Email: dutson@wisc.edu, mattdutson@icloud.com
 * GitHub: https://github.com/uw-loci/syntheticfibergenerator
 *
 * Copyright (c) 2019, Board of Regents of the University of Wisconsin-Madison
 */

package syntheticfibergenerator;

import javax.swing.*;
import java.awt.*;
import java.util.ArrayList;


/**
 * Contains miscellaneous useful static methods.
 */
class MiscUtility {

    /**
     * @return A new {@code GridBagConstraints} object whose {@code gridx} and {@code gridy} members are zero
     */
    static GridBagConstraints newGBC() {
        GridBagConstraints gbc = new GridBagConstraints();
        gbc.gridx = 0;
        gbc.gridy = 0;
        return gbc;
    }

    /**
     * @param param The parameters whose display name is desired
     * @return The GUI "display name" for the input parameter (first letter capitalized with colon added)
     */
    static String guiName(Param param) {
        if (param.name().length() == 0) {
            return ":";
        }
        String name = param.name();
        String uppercase = name.substring(0, 1).toUpperCase() + name.substring(1);
        return uppercase + ":";
    }

    /**
     * Helper used for displaying error dialogs in a consistent format.
     *
     * @param message The message to display
     */
    static void showError(String message) {
        JOptionPane.showMessageDialog(null, message, "Error", JOptionPane.ERROR_MESSAGE);
    }

    /**
     * @param val A value to square
     * @return The squared input
     */
    static double sq(double val) {
        return val * val;
    }

    /**
     * @param val A value to square
     * @return The squared input
     */
    static int sq(int val) {
        return val * val;
    }

    /**
     * Converts an list of 2D points to a list of offsets. The ith element of the output is equal to {@code
     * points.get(i+1).subtract(points.get(i))}.
     *
     * @param points A list of vectors in 2D
     * @return A list of the vector differences between each adjacent pair of points
     */
    static ArrayList<Vector> toDeltas(ArrayList<Vector> points) {
        ArrayList<Vector> deltas = new ArrayList<>();
        for (int i = 0; i < points.size() - 1; i++) {
            deltas.add(points.get(i + 1).subtract(points.get(i)));
        }
        return deltas;
    }

    /**
     * Reverses the output of {@code toDeltas}.
     *
     * @param deltas The output of {@code toDeltas}
     * @param start  The first point in the output
     * @return A list of vectors in 2D
     */
    static ArrayList<Vector> fromDeltas(ArrayList<Vector> deltas, Vector start) {
        ArrayList<Vector> points = new ArrayList<>();
        points.add(start);
        for (int i = 0; i < deltas.size(); i++) {
            points.add(i + 1, points.get(i).add(deltas.get(i)));
        }
        return points;
    }
}
