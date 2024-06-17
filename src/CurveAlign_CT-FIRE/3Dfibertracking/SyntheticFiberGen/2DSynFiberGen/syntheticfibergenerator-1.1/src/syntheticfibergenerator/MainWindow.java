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

import java.awt.*;
import java.awt.event.ActionEvent;
import java.awt.image.AffineTransformOp;
import java.awt.image.BufferedImage;
import java.io.*;
import javax.swing.*;
import javax.swing.filechooser.FileNameExtensionFilter;


/**
 * The main GUI which displays on startup.
 */
class MainWindow extends JFrame {

    // Can be modified via the "Output location" button, therefore not final
    private String outFolder = "output" + File.separator;

    // Used for reading/writing parameters
    private IOManager IOManager;

    // Current parameters
    private ImageCollection.Params params;

    // Current image stack
    private ImageCollection collection;

    // Index of the currently displayed image
    private int displayIndex;

    // Elements of the display panel
    private JLabel imageDisplay;
    private JButton prevButton;
    private JButton nextButton;

    private JButton generateButton;

    // Elements of the "Session" panel
    private JButton loadButton;
    private JButton saveButton;
    private JTextField pathDisplay;
    private JTextField nImagesField;
    private JCheckBox seedCheck;
    private JTextField seedField;

    // Elements of the "Distributions" panel
    private JButton lengthButton;
    private JTextField lengthDisplay;
    private JButton widthButton;
    private JTextField widthDisplay;
    private JButton straightButton;
    private JTextField straightDisplay;

    // Elements of the "Values" panel
    private JTextField nFibersField;
    private JTextField segmentField;
    private JTextField widthChangeField;
    private JTextField alignmentField;
    private JTextField meanAngleField;

    // Elements of the "Required" panel
    private JTextField imageWidthField;
    private JTextField imageHeightField;
    private JTextField imageBufferField;

    // Elements of the "Optional" panel
    private JCheckBox scaleCheck;
    private JTextField scaleField;
    private JCheckBox sampleCheck;
    private JTextField sampleField;
    private JCheckBox blurCheck;
    private JTextField blurField;
    private JCheckBox noiseCheck;
    private JTextField noiseField;
    private JCheckBox distanceCheck;
    private JTextField distanceField;
    private JCheckBox capCheck;
    private JTextField capField;
    private JCheckBox normalizeCheck;
    private JTextField normalizeField;

    // Elements of the "Smoothing" panel
    private JCheckBox bubbleCheck;
    private JTextField bubbleField;
    private JCheckBox swapCheck;
    private JTextField swapField;
    private JCheckBox splineCheck;
    private JTextField splineField;

    // Size of the GUI image display label
    private static final int IMAGE_DISPLAY_SIZE = 512;

    // Where to look for the defaults file
    private static final String DEFAULTS_FILE = "defaults.json";


    /**
     * Reads parameters from the defaults file and initializes the GUI.
     */
    MainWindow() {
        super("Fiber Generator");
        IOManager = new IOManager();
        try {
            params = IOManager.readParamsFile(DEFAULTS_FILE);
        } catch (Exception e) {
            MiscUtility.showError(e.getMessage());
        }
        initGUI();
        displayParams();
        setVisible(true);
    }

    /**
     * Sets up GUI components and behavior.
     */
    private void initGUI() {
        setDefaultCloseOperation(WindowConstants.EXIT_ON_CLOSE);
        setLayout(new GridBagLayout());

        GridBagConstraints gbc = MiscUtility.newGBC();

        JPanel displayPanel = new JPanel(new GridBagLayout());
        gbc.gridheight = 2;
        add(displayPanel, gbc);

        JTabbedPane tabbedPane = new JTabbedPane(JTabbedPane.TOP);
        gbc.anchor = GridBagConstraints.NORTH;
        gbc.gridheight = 1;
        gbc.gridx++;
        add(tabbedPane, gbc);

        generateButton = new JButton("Generate...");
        gbc.fill = GridBagConstraints.HORIZONTAL;
        gbc.insets = new Insets(5, 10, 5, 10);
        gbc.gridy++;
        add(generateButton, gbc);

        gbc = MiscUtility.newGBC();

        JPanel generationPanel = new JPanel(new GridBagLayout());
        tabbedPane.addTab("Generation", null, generationPanel);
        JPanel structurePanel = new JPanel(new GridBagLayout());
        tabbedPane.addTab("Structure", null, structurePanel);
        JPanel appearancePanel = new JPanel(new GridBagLayout());
        tabbedPane.addTab("Appearance", null, appearancePanel);

        imageDisplay = createImageDisplay();
        gbc.gridwidth = 2;
        displayPanel.add(imageDisplay, gbc);

        gbc = MiscUtility.newGBC();

        prevButton = new JButton("Previous");
        gbc.anchor = GridBagConstraints.EAST;
        gbc.insets = new Insets(5, 5, 5, 5);
        gbc.weightx = 100;
        gbc.gridy = 1;
        displayPanel.add(prevButton, gbc);

        nextButton = new JButton("Next");
        gbc.anchor = GridBagConstraints.WEST;
        gbc.gridx++;
        nextButton.setPreferredSize(prevButton.getPreferredSize());
        displayPanel.add(nextButton, gbc);

        gbc = MiscUtility.newGBC();

        OptionPanel session = new OptionPanel("Session");
        gbc.anchor = GridBagConstraints.NORTHWEST;
        gbc.insets = new Insets(5, 5, 5, 5);
        gbc.ipadx = 10;
        gbc.ipady = 10;
        gbc.weightx = 100;
        gbc.weighty = 100;
        generationPanel.add(session, gbc);

        OptionPanel distribution = new OptionPanel("Distributions");
        gbc.weighty = 0;
        gbc.gridy = 0;
        structurePanel.add(distribution, gbc);

        OptionPanel values = new OptionPanel("Values");
        gbc.weighty = 100;
        gbc.gridy++;
        structurePanel.add(values, gbc);

        OptionPanel required = new OptionPanel("Required");
        gbc.weighty = 0;
        gbc.gridy = 0;
        appearancePanel.add(required, gbc);

        OptionPanel optional = new OptionPanel("Optional");
        gbc.gridy++;
        appearancePanel.add(optional, gbc);

        OptionPanel smooth = new OptionPanel("Smoothing");
        gbc.weighty = 100;
        gbc.gridy++;
        appearancePanel.add(smooth, gbc);

        loadButton = session.addButtonLine(
                "Parameters:", "Choose parameters file to restore a previous session", "Open...");
        saveButton = session.addButtonLine("Output location:", "Choose directory for output", "Open...");
        pathDisplay = session.addDisplayField();
        nImagesField = session.addFieldLine(params.nImages);
        seedCheck = session.addCheckBox(params.seed);
        seedField = session.addField();

        lengthButton = distribution.addButtonLine(
                "Length distribution:", "Distribution of fiber lengths in pixels", "Modify...");
        lengthDisplay = distribution.addDisplayField();
        widthButton = distribution.addButtonLine(
                "Width distribution:", "Distribution of starting widths in pixels", "Modify...");
        widthDisplay = distribution.addDisplayField();
        straightButton = distribution.addButtonLine(
                "Straightness distribution:", "Distribution of fiber straightnesses", "Modify...");
        straightDisplay = distribution.addDisplayField();

        nFibersField = values.addFieldLine(params.nFibers);
        segmentField = values.addFieldLine(params.segmentLength);
        widthChangeField = values.addFieldLine(params.widthChange);
        alignmentField = values.addFieldLine(params.alignment);
        meanAngleField = values.addFieldLine(params.meanAngle);

        imageWidthField = required.addFieldLine(params.imageWidth);
        imageHeightField = required.addFieldLine(params.imageHeight);
        imageBufferField = required.addFieldLine(params.imageBuffer);

        scaleCheck = optional.addCheckBox(params.scale);
        scaleField = optional.addField();
        sampleCheck = optional.addCheckBox(params.downSample);
        sampleField = optional.addField();
        blurCheck = optional.addCheckBox(params.blur);
        blurField = optional.addField();
        noiseCheck = optional.addCheckBox(params.noise);
        noiseField = optional.addField();
        distanceCheck = optional.addCheckBox(params.distance);
        distanceField = optional.addField();
        capCheck = optional.addCheckBox(params.cap);
        capField = optional.addField();
        normalizeCheck = optional.addCheckBox(params.normalize);
        normalizeField = optional.addField();

        bubbleCheck = smooth.addCheckBox(params.bubble);
        bubbleField = smooth.addField();
        swapCheck = smooth.addCheckBox(params.swap);
        swapField = smooth.addField();
        splineCheck = smooth.addCheckBox(params.spline);
        splineField = smooth.addField();

        setupListeners();
        setResizable(false);
        pack();
    }

    /**
     * Updates the GUI to reflect the program's logical state.
     */
    private void displayParams() {
        pathDisplay.setPreferredSize(pathDisplay.getSize());
        pathDisplay.setText(outFolder);
        pathDisplay.setToolTipText(outFolder);

        nImagesField.setText(params.nImages.string());
        seedCheck.setSelected(params.seed.use);
        seedField.setText(params.seed.string());

        lengthDisplay.setPreferredSize(lengthDisplay.getSize());
        lengthDisplay.setText(params.length.getString());
        widthDisplay.setPreferredSize(widthDisplay.getSize());
        widthDisplay.setText(params.width.getString());
        straightDisplay.setPreferredSize(straightDisplay.getSize());
        straightDisplay.setText(params.straightness.getString());

        nFibersField.setText(params.nFibers.string());
        segmentField.setText(params.segmentLength.string());
        widthChangeField.setText(params.widthChange.string());
        alignmentField.setText(params.alignment.string());
        meanAngleField.setText(params.meanAngle.string());

        imageWidthField.setText(params.imageWidth.string());
        imageHeightField.setText(params.imageHeight.string());
        imageBufferField.setText(params.imageBuffer.string());

        scaleCheck.setSelected(params.scale.use);
        scaleField.setText(params.scale.string());
        sampleCheck.setSelected(params.downSample.use);
        sampleField.setText(params.downSample.string());
        blurCheck.setSelected(params.blur.use);
        blurField.setText(params.blur.string());
        noiseCheck.setSelected(params.noise.use);
        noiseField.setText(params.noise.string());
        distanceCheck.setSelected(params.distance.use);
        distanceField.setText(params.distance.string());
        capCheck.setSelected(params.cap.use);
        capField.setText(params.cap.string());
        normalizeCheck.setSelected(params.normalize.use);
        normalizeField.setText(params.normalize.string());

        bubbleCheck.setSelected(params.bubble.use);
        bubbleField.setText(params.bubble.string());
        swapCheck.setSelected(params.swap.use);
        swapField.setText(params.swap.string());
        splineCheck.setSelected(params.spline.use);
        splineField.setText(params.spline.string());
    }

    /**
     * Attempts to parse parameters from the GUI and store them in {@code params}.
     *
     * @throws IllegalArgumentException If parsing fails for any parameters
     */
    private void parseParams() throws IllegalArgumentException {
        params.nImages.parse(nImagesField.getText(), Integer::parseInt);
        params.seed.parse(seedCheck.isSelected(), seedField.getText(), Long::parseLong);

        params.nFibers.parse(nFibersField.getText(), Integer::parseInt);
        params.segmentLength.parse(segmentField.getText(), Double::parseDouble);
        params.widthChange.parse(widthChangeField.getText(), Double::parseDouble);
        params.alignment.parse(alignmentField.getText(), Double::parseDouble);
        params.meanAngle.parse(meanAngleField.getText(), Double::parseDouble);

        params.imageWidth.parse(imageWidthField.getText(), Integer::parseInt);
        params.imageHeight.parse(imageHeightField.getText(), Integer::parseInt);
        params.imageBuffer.parse(imageBufferField.getText(), Integer::parseInt);

        params.scale.parse(scaleCheck.isSelected(), scaleField.getText(), Double::parseDouble);
        params.downSample.parse(sampleCheck.isSelected(), sampleField.getText(), Double::parseDouble);
        params.blur.parse(blurCheck.isSelected(), blurField.getText(), Double::parseDouble);
        params.noise.parse(noiseCheck.isSelected(), noiseField.getText(), Double::parseDouble);
        params.distance.parse(distanceCheck.isSelected(), distanceField.getText(), Double::parseDouble);
        params.cap.parse(capCheck.isSelected(), capField.getText(), Integer::parseInt);
        params.normalize.parse(normalizeCheck.isSelected(), normalizeField.getText(), Integer::parseInt);

        params.bubble.parse(bubbleCheck.isSelected(), bubbleField.getText(), Integer::parseInt);
        params.swap.parse(swapCheck.isSelected(), swapField.getText(), Integer::parseInt);
        params.spline.parse(splineCheck.isSelected(), splineField.getText(), Integer::parseInt);
    }

    /**
     * Displays the input image to the fixed-size element {@code imageDisplay}.
     *
     * @param image The image to display
     */
    private void displayImage(BufferedImage image) {
        double xScale = (double) IMAGE_DISPLAY_SIZE / image.getWidth();
        double yScale = (double) IMAGE_DISPLAY_SIZE / image.getHeight();
        double scale = Math.min(xScale, yScale);
        BufferedImage scaled = ImageUtility.scale(image, scale, AffineTransformOp.TYPE_NEAREST_NEIGHBOR);

        Icon icon = new ImageIcon(scaled);
        imageDisplay.setText(null);
        imageDisplay.setIcon(icon);
    }

    /**
     * Sets listeners for all buttons
     */
    private void setupListeners() {
        generateButton.addActionListener((ActionEvent e) -> generatePressed());
        prevButton.addActionListener((ActionEvent e) -> prevPressed());
        nextButton.addActionListener((ActionEvent e) -> nextPressed());
        lengthButton.addActionListener((ActionEvent e) -> lengthPressed());
        straightButton.addActionListener((ActionEvent e) -> straightPressed());
        widthButton.addActionListener((ActionEvent e) -> widthPressed());
        loadButton.addActionListener((ActionEvent e) -> loadPressed());
        saveButton.addActionListener((ActionEvent e) -> savePressed());
    }

    /**
     * Parsers and verifies parameters, generates images, and saves output. Shows an error dialog on failure.
     */
    private void generatePressed() {
        try {
            parseParams();
            collection = new ImageCollection(params);
            collection.generateImages();
            IOManager.writeResults(params, collection, outFolder);
        } catch (IllegalArgumentException e) {
            MiscUtility.showError(e.getMessage());
            return;
        } catch (ArithmeticException e) {
            MiscUtility.showError("Unable to construct fibers - change parameters and try again");
            return;
        } catch (IOException e) {
            MiscUtility.showError(e.getMessage());
        }
        displayIndex = 0;
        displayImage(collection.getImage(displayIndex));
    }

    /**
     * Decreases {@code displayIndex} by one and updates the image display. No action is taken if the index is zero or
     * the image stack is empty.
     */
    private void prevPressed() {
        if (!collection.isEmpty() && displayIndex > 0) {
            displayIndex--;
            displayImage(collection.getImage(displayIndex));
        }
    }

    /**
     * Increases {@code displayIndex} by one and updates the image display. No action is taken if the index points to
     * the last image in the stack or the image stack is empty.
     */
    private void nextPressed() {
        if (!collection.isEmpty() && displayIndex < collection.size() - 1) {
            displayIndex++;
            displayImage(collection.getImage(displayIndex));
        }
    }

    /**
     * Prompts the user for a parameters file and then loads those parameters into the GUI.
     */
    private void loadPressed() {
        File workingDirectory = new File(System.getProperty("user.dir"));
        JFileChooser chooser = new JFileChooser(workingDirectory);
        chooser.setFileFilter(new FileNameExtensionFilter("JSON files", "json"));
        chooser.setFileSelectionMode(JFileChooser.FILES_ONLY);
        if (chooser.showOpenDialog(null) == JFileChooser.APPROVE_OPTION) {
            try {
                params = IOManager.readParamsFile(chooser.getSelectedFile().getAbsolutePath());
            } catch (IOException e) {
                MiscUtility.showError(e.getMessage());
            }
        }
        displayParams();
    }

    /**
     * Prompts the user for a directory where output will be saved.
     */
    private void savePressed() {
        File workingDirectory = new File(System.getProperty("user.dir"));
        JFileChooser chooser = new JFileChooser(workingDirectory);
        chooser.setFileSelectionMode(JFileChooser.DIRECTORIES_ONLY);
        int returnVal = chooser.showSaveDialog(null);
        if (returnVal == JFileChooser.APPROVE_OPTION) {
            if (chooser.getSelectedFile().isDirectory()) {
                outFolder = chooser.getSelectedFile().getAbsolutePath() + File.separator;
            } else {
                outFolder = chooser.getCurrentDirectory().getAbsolutePath() + File.separator;
            }
            displayParams();
        }
    }

    /**
     * Allows the user to modify the {@code length} distribution via a {@code DistributionDialog}.
     */
    private void lengthPressed() {
        DistributionDialog dialog = new DistributionDialog(params.length);
        params.length = dialog.distribution;
        displayParams();
    }

    /**
     * Allows the user to modify the {@code width} distribution via a {@code DistributionDialog}.
     */
    private void widthPressed() {
        DistributionDialog dialog = new DistributionDialog(params.width);
        params.width = dialog.distribution;
        displayParams();
    }

    /**
     * Allows the user to modify the {@code straightness} distribution via a {@code DistributionDialog}.
     */
    private void straightPressed() {
        DistributionDialog dialog = new DistributionDialog(params.straightness);
        params.straightness = dialog.distribution;
        displayParams();
    }

    /**
     * @return A {@code JLabel} where fiber images can be displayed
     */
    private static JLabel createImageDisplay() {
        JLabel output = new JLabel("Press \"Generate\" to view images");
        output.setHorizontalAlignment(JLabel.CENTER);
        output.setForeground(Color.WHITE);
        output.setBackground(Color.BLACK);
        output.setOpaque(true);
        output.setPreferredSize(new Dimension(IMAGE_DISPLAY_SIZE, IMAGE_DISPLAY_SIZE));
        return output;
    }
}