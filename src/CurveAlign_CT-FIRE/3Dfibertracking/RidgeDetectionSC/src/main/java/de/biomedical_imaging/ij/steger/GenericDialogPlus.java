/*
 * #%L
 * Ridge Detection plugin for ImageJ
 * %%
 * Copyright (C) 2014 - 2015 Thorsten Wagner (ImageJ java plugin), 1996-1998 Carsten Steger (original C code), 1999 R. Balasubramanian (detect lines code to incorporate within GRASP)
 * %%
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as
 * published by the Free Software Foundation, either version 2 of the
 * License, or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public
 * License along with this program.  If not, see
 * <http://www.gnu.org/licenses/gpl-2.0.html>.
 * #L%
 */
package de.biomedical_imaging.ij.steger;

import ij.ImagePlus;
import ij.WindowManager;
import ij.gui.GenericDialog;
import ij.io.OpenDialog;

import java.awt.Button;
import java.awt.Component;
import java.awt.FlowLayout;
import java.awt.Frame;
import java.awt.GraphicsEnvironment;
import java.awt.GridBagConstraints;
import java.awt.GridBagLayout;
import java.awt.Panel;
import java.awt.TextField;
import java.awt.Toolkit;
import java.awt.datatransfer.DataFlavor;
import java.awt.datatransfer.UnsupportedFlavorException;
import java.awt.dnd.DnDConstants;
import java.awt.dnd.DropTarget;
import java.awt.dnd.DropTargetAdapter;
import java.awt.dnd.DropTargetDropEvent;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.awt.event.KeyEvent;
import java.io.File;
import java.io.IOException;
import java.net.URL;
import java.util.List;

import javax.swing.ImageIcon;
import javax.swing.JFileChooser;
import javax.swing.JLabel;

/**
 * The GenericDialogPlus class enhances the GenericDialog by
 * a few additional methods.
 *
 * It adds a method to add a file chooser, a dialog chooser,
 * an image chooser, a button, and makes string (and file) fields
 * drop targets.
 */
public class GenericDialogPlus extends GenericDialog {
	private static final long serialVersionUID = 1L;

	protected int[] windowIDs;
	protected String[] windowTitles;

	public GenericDialogPlus(String title) {
		super(title);
	}

	public GenericDialogPlus(String title, Frame parent) {
		super(title, parent);
	}

	public void addImageChoice(String label, String defaultImage) {
		if (windowTitles == null) {
			windowIDs = WindowManager.getIDList();
			if (windowIDs == null)
				windowIDs = new int[0];
			windowTitles = new String[windowIDs.length];
			for (int i = 0; i < windowIDs.length; i++) {
				ImagePlus image = WindowManager.getImage(windowIDs[i]);
				windowTitles[i] = image == null ? "" : image.getTitle();
			}
		}
		addChoice(label, windowTitles, defaultImage);
	}

	public ImagePlus getNextImage() {
		return WindowManager.getImage(windowIDs[getNextChoiceIndex()]);
	}

	@Override
	public void addStringField(String label, String defaultString, int columns) {
		super.addStringField(label, defaultString, columns);
		if (isHeadless()) return;

		TextField text = (TextField)stringField.lastElement();
		text.setDropTarget(null);
		new DropTarget(text, new TextDropTarget(text));
	}

	public void addDirectoryOrFileField(String label, String defaultPath) {
		addDirectoryOrFileField(label, defaultPath, 20);
	}

	public void addDirectoryOrFileField(String label, String defaultPath, int columns) {
		addStringField(label, defaultPath, columns);
		if (isHeadless()) return;

		TextField text = (TextField)stringField.lastElement();
		GridBagLayout layout = (GridBagLayout)getLayout();
		GridBagConstraints constraints = layout.getConstraints(text);

		Button button = new Button("Browse...");
		DirectoryListener listener = new DirectoryListener("Browse for " + label, text, JFileChooser.FILES_AND_DIRECTORIES);
		button.addActionListener(listener);
		button.addKeyListener(this);

		Panel panel = new Panel();
		panel.setLayout(new FlowLayout(FlowLayout.LEFT, 0, 0));
		panel.add(text);
		panel.add(button);

		layout.setConstraints(panel, constraints);
		add(panel);
	}

	public void addDirectoryField(String label, String defaultPath) {
		addDirectoryField(label, defaultPath, 20);
	}

	public void addDirectoryField(String label, String defaultPath, int columns) {
		addStringField(label, defaultPath, columns);
		if (isHeadless()) return;

		TextField text = (TextField)stringField.lastElement();
		GridBagLayout layout = (GridBagLayout)getLayout();
		GridBagConstraints constraints = layout.getConstraints(text);

		Button button = new Button("Browse...");
		DirectoryListener listener = new DirectoryListener("Browse for " + label, text);
		button.addActionListener(listener);
		button.addKeyListener(this);

		Panel panel = new Panel();
		panel.setLayout(new FlowLayout(FlowLayout.LEFT, 0, 0));
		panel.add(text);
		panel.add(button);

		layout.setConstraints(panel, constraints);
		add(panel);
	}

	public void addFileField(String label, String defaultPath) {
		addFileField(label, defaultPath, 20);
	}

	public void addFileField(String label, String defaultPath, int columns) {
		addStringField(label, defaultPath, columns);
		if (isHeadless()) return;

		TextField text = (TextField)stringField.lastElement();
		GridBagLayout layout = (GridBagLayout)getLayout();
		GridBagConstraints constraints = layout.getConstraints(text);

		Button button = new Button("Browse...");
		FileListener listener = new FileListener("Browse for " + label, text);
		button.addActionListener(listener);
		button.addKeyListener(this);

		Panel panel = new Panel();
		panel.setLayout(new FlowLayout(FlowLayout.LEFT, 0, 0));
		panel.add(text);
		panel.add(button);

		layout.setConstraints(panel, constraints);
		add(panel);
	}

	/**
	 * Add button to the dialog
	 * @param label button label
	 * @param listener listener to handle the action when pressing the button
	 */
	public void addButton(String label, ActionListener listener) {
		if (isHeadless()) return;

		Button button = new Button(label);

		button.addActionListener(listener);
		button.addKeyListener(this);

		addComponent(button);
	}
	
	public void addComponent(Component component) {
		if (isHeadless()) return;

		GridBagLayout layout = (GridBagLayout)getLayout();
		layout.setConstraints(component, getConstraints());
		add(component);
	}

	public void addComponent(Component component, int fill, double weightx) {
		if (isHeadless()) return;

		GridBagLayout layout = (GridBagLayout)getLayout();
		GridBagConstraints constraints = getConstraints();
		constraints.fill = fill;
		constraints.weightx = weightx;
		layout.setConstraints(component, constraints);
		add(component);
	}
	
	/**
	 * Adds an image to the generic dialog
	 * 
	 * @param path - the path to the image in the jar, e.g. /images/fiji.png (the first / has to be there!)
	 * @return true if the image was found and added, otherwise false
	 */
	public boolean addImage(final String path) {
		if (isHeadless()) return true;

		return addImage(getClass().getResource(path));
	}
	
	/**
	 * Adds an image to the generic dialog
	 * 
	 * @param imgURL - the {@link URL} pointing to the resource
	 * @return true if the image was found and added, otherwise false
	 */
	public boolean addImage(final URL imgURL) {
		if (isHeadless()) return true;

		final ImageIcon image = createImageIcon(imgURL);
		
		if (image == null) return false;
		addImage(image);
		return true;
	}

	/**
	 * Adds an image to the generic dialog
	 * 
	 * @param image - the {@link ImageIcon} to display
	 * @return label - the {@link JLabel} that contains the image for updating:
	 * 
	 * image.setImage(otherImageIcon.getImage());
	 * label.update(label.getGraphics());
	 */
	public JLabel addImage(final ImageIcon image) {
		if (isHeadless()) return null;

		final Panel panel = new Panel();
		panel.setLayout(new FlowLayout(FlowLayout.LEFT, 0, 0));
		final JLabel label = new JLabel(image);
		label.setOpaque(true);
		panel.add(label);
		addPanel(panel);
		
		return label;
	}

	/** Returns an ImageIcon, or null if the path was invalid. */
	public static ImageIcon createImageIcon(final URL imgURL) {
		if (isHeadless()) return null;

		if (imgURL != null) return new ImageIcon(imgURL);
		return null;
	}
	
	// Work around too many private restrictions (add a new panel and remove it right away)
	protected GridBagConstraints getConstraints() {
		GridBagLayout layout = (GridBagLayout)getLayout();
		Panel panel = new Panel();
		addPanel(panel);
		GridBagConstraints constraints = layout.getConstraints(panel);
		remove(panel);
		return constraints;
	}

	private static boolean isHeadless() {
		return GraphicsEnvironment.isHeadless();
	}

	static class FileListener implements ActionListener {
		String title;
		TextField text;

		public FileListener(String title, TextField text) {
			this.title = title;
			this.text = text;
		}

		@Override
		public void actionPerformed(ActionEvent e) {
			String fileName = null;
			File dir = new File(text.getText());
			if (!dir.isDirectory()) {
				if (dir.exists())
					fileName = dir.getName();
				dir = dir.getParentFile();
			}
			while (dir != null && !dir.exists())
				dir = dir.getParentFile();

			OpenDialog dialog;
			if (dir == null)
				dialog = new OpenDialog(title, fileName);
			else
				dialog = new OpenDialog(title, dir.getAbsolutePath(), fileName);
			String directory = dialog.getDirectory();
			if (directory == null)
				return;
			fileName = dialog.getFileName();
			text.setText(directory + File.separator + fileName);
		}
	}

	static class DirectoryListener implements ActionListener {
		String title;
		TextField text;
		int fileSelectionMode;

		public DirectoryListener (String title, TextField text) {
			this(title, text, JFileChooser.DIRECTORIES_ONLY);
		}

		public DirectoryListener (String title, TextField text, int fileSelectionMode) {
			this.title = title;
			this.text = text;
			this.fileSelectionMode = fileSelectionMode;
		}

		@Override
		public void actionPerformed(ActionEvent e) {
			File directory = new File(text.getText());
			while (directory != null && !directory.exists())
				directory = directory.getParentFile();

			JFileChooser fc = new JFileChooser(directory);
			fc.setFileSelectionMode(fileSelectionMode);

			fc.showOpenDialog(null);
			File selFile = fc.getSelectedFile();
			if (selFile != null)
				text.setText(selFile.getAbsolutePath());
		}
	}

	static String stripSuffix(String s, String suffix) {
		return !s.endsWith(suffix) ? s :
			s.substring(0, s.length() - suffix.length());
	}

	@SuppressWarnings("unchecked")
	static String getString(DropTargetDropEvent event)
			throws IOException, UnsupportedFlavorException {
		String text = null;
		DataFlavor fileList = DataFlavor.javaFileListFlavor;

		if (event.isDataFlavorSupported(fileList)) {
			event.acceptDrop(DnDConstants.ACTION_COPY);
			List<File> list = (List<File>)event.getTransferable().getTransferData(fileList);
			text = list.get(0).getAbsolutePath();
		}
		else if (event.isDataFlavorSupported(DataFlavor.stringFlavor)) {
			event.acceptDrop(DnDConstants.ACTION_COPY);
			text = (String)event.getTransferable()
				.getTransferData(DataFlavor.stringFlavor);
			if (text.startsWith("file://"))
				text = text.substring(7);
			text = stripSuffix(stripSuffix(text, "\n"),
					"\r").replaceAll("%20", " ");
		}
		else {
			event.rejectDrop();
			return null;
		}

		event.dropComplete(text != null);
		return text;
	}

	static class TextDropTarget extends DropTargetAdapter {
		TextField text;
		DataFlavor flavor = DataFlavor.stringFlavor;

		public TextDropTarget(TextField text) {
			this.text = text;
		}

		@Override
		public void drop(DropTargetDropEvent event) {
			try {
				text.setText(getString(event));
			} catch (Exception e) { e.printStackTrace(); }
		}
	}

	@Override
	public void keyPressed(KeyEvent e) {
		int keyCode = e.getKeyCode();
		if (keyCode == KeyEvent.VK_ESCAPE || (keyCode == KeyEvent.VK_W &&
				(e.getModifiers() & Toolkit.getDefaultToolkit().getMenuShortcutKeyMask()) != 0))
			// wasCanceled is private; workaround
			windowClosing(null);
	}

	@Override
	public void keyReleased(KeyEvent e) {}
	
	@Override
	public void keyTyped(KeyEvent e) {}

}
