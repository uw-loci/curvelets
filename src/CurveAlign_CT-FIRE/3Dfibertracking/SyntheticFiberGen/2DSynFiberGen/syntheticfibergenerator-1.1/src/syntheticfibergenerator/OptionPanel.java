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


/**
 * A panel used by MainWindow and DistributionDialog. Displays checkboxes and labels on the left with text fields on the
 * right.
 */
class OptionPanel extends JPanel {

    // The current row where new components will be placed
    private int y = 0;

    // Width of a text field
    private static final int FIELD_W = 5;

    // Amount of padding between elements
    private static final int INNER_BUFF = 5;


    /**
     * Default constructor; sets the layout manager.
     */
    OptionPanel() {
        super(new GridBagLayout());
    }

    /**
     * Calls the default constructor and adds a text border.
     *
     * @param borderText The border text
     */
    OptionPanel(String borderText) {
        this();
        setBorder(BorderFactory.createTitledBorder(borderText));
    }

    /**
     * Adds a line to the panel with a label on the left and a button on the right.
     *
     * @param labelText  The label display text
     * @param hintText   The label hover text
     * @param buttonText The button display text
     * @return A reference to the button
     */
    JButton addButtonLine(String labelText, String hintText, String buttonText) {
        addLabel(labelText, hintText);
        return addButton(buttonText);
    }

    /**
     * Adds a line to the panel with a label on the left and a text field on the right.
     *
     * @param param {@code param.name()} and {@code param.hint()} are used to set the label's display text and hover
     *              text respectively
     * @return A reference to the text field
     */
    JTextField addFieldLine(Param param) {
        addLabel(MiscUtility.guiName(param), param.hint());
        return addField();
    }

    /**
     * Adds a read-only text field on the left.
     *
     * @return A reference to the text field
     */
    JTextField addReadOnlyField() {
        JTextField field = addField();
        field.setEditable(false);
        return field;
    }

    /**
     * Adds a panel-spanning read-only text field.
     *
     * @return A reference to the text field
     */
    JTextField addDisplayField() {
        GridBagConstraints gbc = new GridBagConstraints();
        gbc.fill = GridBagConstraints.HORIZONTAL;
        gbc.gridwidth = 2;
        gbc.gridx = 0;
        gbc.gridy = y;
        JTextField field = new JTextField();
        field.setBorder(BorderFactory.createEmptyBorder(0, 0, 15, 0));
        field.setOpaque(false);
        field.setEditable(false);
        add(field, gbc);
        y++;
        return field;
    }

    /**
     * Adds a text field on the right.
     *
     * @return A reference to the text field
     */
    JTextField addField() {
        GridBagConstraints gbc = gbcRight();
        JTextField field = new JTextField(FIELD_W);
        add(field, gbc);
        y++;
        return field;
    }

    /**
     * Adds a label on the left.
     *
     * @param labelText The label display text
     * @param hintText  The label hover text
     * @return A reference to the label
     */
    JLabel addLabel(String labelText, String hintText) {
        GridBagConstraints gbc = gbcLeft();
        JLabel label = new JLabel(labelText);
        label.setToolTipText(hintText);
        add(label, gbc);
        return label;
    }

    /**
     * Adds a checkbox on the left.
     *
     * @param option {@code option.use}, {@code option.name()}, and {@code option.hint()} are used to set the checkbox
     *               selected status, the label's display text, and the label's hover text respectively
     * @return A reference to the checkbox
     */
    JCheckBox addCheckBox(Optional option) {
        GridBagConstraints gbc = gbcLeft();
        JCheckBox box = new JCheckBox(MiscUtility.guiName(option));
        box.setToolTipText(option.hint());
        add(box, gbc);
        return box;
    }

    /**
     * Adds a button on the right.
     *
     * @param labelText The button display text
     * @return A reference to the button
     */
    private JButton addButton(String labelText) {
        GridBagConstraints gbc = gbcRight();
        JButton button = new JButton(labelText);
        add(button, gbc);
        y++;
        return button;
    }

    /**
     * @return A {@code GridBagConstraints} which can be used to place a component on the left side of the panel.
     */
    private GridBagConstraints gbcLeft() {
        GridBagConstraints gbc = new GridBagConstraints();
        gbc.insets = new Insets(0, 0, 0, INNER_BUFF);
        gbc.anchor = GridBagConstraints.WEST;
        gbc.gridx = 0;
        gbc.gridy = y;
        return gbc;
    }

    /**
     * @return A {@code GridBagConstraints} which can be used to place a component on the right side of the panel.
     */
    private GridBagConstraints gbcRight() {
        GridBagConstraints gbc = new GridBagConstraints();
        gbc.insets = new Insets(0, INNER_BUFF, 0, 0);
        gbc.anchor = GridBagConstraints.WEST;
        gbc.gridx = 1;
        gbc.gridy = y;
        return gbc;
    }
}
