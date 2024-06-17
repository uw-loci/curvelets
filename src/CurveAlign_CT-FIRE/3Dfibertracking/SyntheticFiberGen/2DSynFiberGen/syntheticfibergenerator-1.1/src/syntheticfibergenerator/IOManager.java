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

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.google.gson.JsonParseException;

import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.*;


/**
 * Class used for reading/writing parameters and writing results.
 */
class IOManager {

    // Save serializer and deserializer so we don't have to re-construct them
    private Gson serializer;
    private Gson deserializer;

    // Starting portion of name for data files
    private static final String DATA_PREFIX = "data";

    // Starting portion of name for image files
    private static final String IMAGE_PREFIX = "image";

    // Image filename extension
    private static final String IMAGE_EXT = "png";


    /**
     * Sets up the JSON serializer and deserializer.
     */
    IOManager() {
        serializer = new GsonBuilder()
                .setPrettyPrinting()
                .serializeSpecialFloatingPointValues()
                .registerTypeAdapter(Distribution.class, new Distribution.Serializer())
                .create();
        deserializer = new GsonBuilder()
                .registerTypeAdapter(Distribution.class, new Distribution.Deserializer())
                .create();
    }

    /**
     * Attempts to read and deserialize a JSON file to an {@code ImageCollection.Params} object.
     *
     * @param filename The path of the JSON file to deserialize
     * @return A {@code ImageCollection.Params} object
     * @throws IOException If there an error occurred during reading and parsing the parameters file
     */
    ImageCollection.Params readParamsFile(String filename) throws IOException {
        ImageCollection.Params params;
        try {
            FileReader reader = new FileReader(filename);
            params = deserializer.fromJson(reader, ImageCollection.Params.class);
            reader.close();
        } catch (FileNotFoundException e) {
            throw new IOException("File \"" + filename + "\" not found");
        } catch (IOException e) {
            throw new IOException("Error when reading \"" + filename + '\"');
        } catch (JsonParseException e) {
            throw new IOException("Malformed parameters file \"" + filename + '\"');
        }
        params.length.setBounds(0, Double.POSITIVE_INFINITY);
        params.straightness.setBounds(0, 1);
        params.width.setBounds(0, Double.POSITIVE_INFINITY);
        params.setNames();
        params.setHints();
        return params;
    }

    /**
     * Writes an image and JSON data file for each {@code FiberImage} in the collection. Also records the given
     * parameters in a JSON file.
     *
     * @param params     The parameters to record
     * @param collection The collection of {@code FiberImage} objects to write
     * @param outFolder  The path (with folder separator) where output should be written
     * @throws IOException If any of the file writes fail
     */
    void writeResults(ImageCollection.Params params, ImageCollection collection, String outFolder) throws IOException {
        writeStringFile(outFolder + "params.json", serializer.toJson(params, ImageCollection.Params.class));
        for (int i = 0; i < collection.size(); i++) {
            String imagePrefix = outFolder + IMAGE_PREFIX + i;
            writeImageFile(imagePrefix, collection.getImage(i));
            String dataFilename = outFolder + DATA_PREFIX + i + ".json";
            writeStringFile(dataFilename, serializer.toJson(collection.get(i), FiberImage.class));
        }
    }

    /**
     * Writes a string to a file.
     *
     * @param filename The name of the file to write
     * @param contents The contents of the file
     * @throws IOException If the file write fails
     */
    private void writeStringFile(String filename, String contents) throws IOException {
        try {
            FileWriter writer = new FileWriter(filename);
            writer.write(contents);
            writer.flush();
            writer.close();
        } catch (IOException e) {
            throw new IOException("Error while writing \"" + filename + '\"');
        }
    }

    /**
     * Writes a {@code BufferedImage} to a file. The image format is given by {@code IMAGE_EXT}.
     *
     * @param prefix The filename up to, but not including the extension
     * @param image  The {@code BufferedImage} to write
     * @throws IOException If the image write fails
     */
    private void writeImageFile(String prefix, BufferedImage image) throws IOException {
        String filename = prefix + '.' + IMAGE_EXT;
        try {
            ImageIO.write(image, IMAGE_EXT, new File(filename));
        } catch (IOException e) {
            throw new IOException("Error while writing \"" + filename + '\"');
        }
    }
}
