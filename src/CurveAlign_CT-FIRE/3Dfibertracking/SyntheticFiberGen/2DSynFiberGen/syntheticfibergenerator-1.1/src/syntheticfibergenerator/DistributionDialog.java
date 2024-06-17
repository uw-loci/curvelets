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
import java.awt.event.*;


/**
 * A GUI dialog which allows the user to select a distribution type and specify its parameters.
 */
class DistributionDialog extends JDialog {

    // The current distribution selected
    Distribution distribution;

    // Saves the original distribution in case "Cancel" is pressed
    private Distribution original;

    // GUI elements
    private JComboBox<String> comboBox;
    private JLabel label1;
    private JTextField field1;
    private JLabel label2;
    private JTextField field2;
    private JButton okayButton;
    private JButton cancelButton;


    /**
     * @param distribution The distribution to display initially. The {@code distribution} member reverts to this if
     *                     "Cancel" is pressed.
     */
    DistributionDialog(Distribution distribution) {
        super();
        this.original = (Distribution) distribution.clone();
        this.distribution = distribution;
        initGUI();
        displayDistribution();
        setVisible(true);
    }

    /**
     * Sets up GUI components and behavior.
     */
    private void initGUI() {

        // Pause the caller until this window is disposed
        setModal(true);

        setDefaultCloseOperation(JDialog.DO_NOTHING_ON_CLOSE);
        setLayout(new GridBagLayout());

        GridBagConstraints gbc = MiscUtility.newGBC();

        String[] options = {Gaussian.typename, Uniform.typename, PiecewiseLinear.typename};
        comboBox = new JComboBox<>(options);
        gbc.fill = GridBagConstraints.HORIZONTAL;
        gbc.gridwidth = 2;
        add(comboBox, gbc);

        gbc = MiscUtility.newGBC();

        OptionPanel panel = new OptionPanel();
        gbc.gridwidth = 2;
        gbc.gridy = 1;
        add(panel, gbc);

        panel.addLabel("Lower bound:", "Minimum allowed value (inclusive)");
        panel.addReadOnlyField().setText(Double.toString(distribution.lowerBound));
        panel.addLabel("Upper bound:", "Maximum allowed value (inclusive)");
        panel.addReadOnlyField().setText(Double.toString(distribution.upperBound));
        label1 = panel.addLabel("", "");
        field1 = panel.addField();
        label2 = panel.addLabel("", "");
        field2 = panel.addField();

        gbc = MiscUtility.newGBC();

        cancelButton = new JButton("Cancel");
        gbc.anchor = GridBagConstraints.WEST;
        gbc.insets = new Insets(5, 5, 5, 5);
        gbc.weightx = 100;
        gbc.gridx = 1;
        gbc.gridy = 2;
        add(cancelButton, gbc);

        okayButton = new JButton("Okay");
        gbc.anchor = GridBagConstraints.EAST;
        gbc.gridx = 0;
        okayButton.setPreferredSize(cancelButton.getPreferredSize());
        add(okayButton, gbc);

        setupListeners();
        setResizable(false);
        pack();
    }

    /**
     * Refreshes the GUI to reflect the state of the {@code distribution} member.
     */
    private void displayDistribution() {
        comboBox.setSelectedItem(distribution.getType());
        if (distribution instanceof Gaussian) {
            Gaussian gaussian = (Gaussian) distribution;
            label1.setText(MiscUtility.guiName(gaussian.mean));
            label1.setToolTipText(gaussian.mean.hint());
            field1.setText(gaussian.mean.string());
            label2.setText(MiscUtility.guiName(gaussian.sigma));
            label2.setToolTipText(gaussian.sigma.hint());
            field2.setText(gaussian.sigma.string());
        } else if (distribution instanceof Uniform) {
            Uniform uniform = (Uniform) distribution;
            label1.setText(MiscUtility.guiName(uniform.min));
            label1.setToolTipText(uniform.min.hint());
            field1.setText(uniform.min.string());
            label2.setText(MiscUtility.guiName(uniform.max));
            label2.setToolTipText(uniform.max.hint());
            field2.setText(uniform.max.string());
        } else if (distribution instanceof PiecewiseLinear) {
            PiecewiseLinear piecewiseLinear = (PiecewiseLinear) distribution;
            label1.setText("X values:");
            label1.setToolTipText("X values of points in the piecewise linear distribution");
            field1.setText(piecewiseLinear.getXString());
            label2.setText("Y values:");
            label2.setToolTipText("Y values of points in the piecewise linear distribution");
            field2.setText(piecewiseLinear.getYString());
        }
    }

    /**
     * Sets listeners for the distribution combo box, "Okay" button, and "Cancel" button.
     */
    private void setupListeners() {
        comboBox.addActionListener((ActionEvent e) -> selectionChanged());
        okayButton.addActionListener((ActionEvent e) -> okayPressed());
        cancelButton.addActionListener((ActionEvent e) -> cancelPressed());
        this.addWindowListener(new WindowAdapter() {
            @Override
            public void windowClosing(WindowEvent e) {
                cancelPressed();
            }
        });
    }

    /**
     * If the distribution type has changed, the {@code distribution} member is modified and a GUI refresh is triggered.
     */
    private void selectionChanged() {
        if (comboBox.getSelectedItem() != null) {
            String selection = comboBox.getSelectedItem().toString();
            if (!selection.equals(distribution.getType())) {
                switch (selection) {
                    case Gaussian.typename:
                        distribution = new Gaussian(distribution.lowerBound, distribution.upperBound);
                        break;
                    case Uniform.typename:
                        distribution = new Uniform(distribution.lowerBound, distribution.upperBound);
                        break;
                    case PiecewiseLinear.typename:
                        distribution = new PiecewiseLinear(distribution.lowerBound, distribution.upperBound);
                        break;
                }
            }
            displayDistribution();
        }
    }

    /**
     * If "Okay" is pressed, modify the {@code distribution} member (for the caller to read) and dispose of the window.
     * This resumes execution of the caller.
     */
    private void okayPressed() {
        if (comboBox.getSelectedItem() == null) {
            MiscUtility.showError("No distribution type selected");
        } else {
            String selection = comboBox.getSelectedItem().toString();
            try {
                switch (selection) {
                    case Gaussian.typename:
                        Gaussian gaussian = (Gaussian) distribution;
                        gaussian.mean.parse(field1.getText(), Double::parseDouble);
                        gaussian.sigma.parse(field2.getText(), Double::parseDouble);
                        break;
                    case Uniform.typename:
                        Uniform uniform = (Uniform) distribution;
                        uniform.min.parse(field1.getText(), Double::parseDouble);
                        uniform.max.parse(field2.getText(), Double::parseDouble);
                        break;
                    case PiecewiseLinear.typename:
                        PiecewiseLinear piecewiseLinear = (PiecewiseLinear) distribution;
                        piecewiseLinear.parseXYValues(field1.getText(), field2.getText());
                        break;
                }
                distribution.verify();
                dispose();
            } catch (IllegalArgumentException e) {
                MiscUtility.showError(e.getMessage());
            }
        }
    }

    /**
     * If "Cancel" is pressed, reset {@code distribution} to its original value and dispose of the window. This resumes
     * execution of the caller.
     */
    private void cancelPressed() {
        this.distribution = original;
        dispose();
    }
}
