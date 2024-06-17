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

import java.awt.image.BufferedImage;
import java.util.ArrayList;
import java.util.Random;


/**
 * Represents a stack of fiber images.
 */
class ImageCollection {

    /**
     * The information needed to construct a stack of fiber images.
     */
    static class Params extends FiberImage.Params {

        Param<Integer> nImages = new Param<>();
        Optional<Long> seed = new Optional<>();


        /**
         * This isn't part of the constructor because ImageCollection.Params objects are often constructed during their
         * deserialization from JSON and the JSON representation doesn't contain names.
         */
        void setNames() {
            super.setNames();
            nImages.setName("number of images");
            seed.setName("seed");
        }

        /**
         * Not part of the constructor for the same reason as setNames().
         */
        void setHints() {
            super.setHints();
            nImages.setHint("The number of images to generate");
            seed.setHint("Check to fix the random seed; value is the seed");
        }

        /**
         * Verifies that all parameters are within the correct bounds.
         *
         * @throws IllegalArgumentException If any parameters are out of bounds
         */
        void verify() throws IllegalArgumentException {
            super.verify();
            nImages.verify(0, Param::greater);
        }
    }


    // Parameters used to construct the image stack
    private Params params;

    // The image stack
    private ArrayList<FiberImage> imageStack;


    /**
     * Note that this doesn't generate images, it just instantiates the underlying data structures. {@code
     * ImageCollection.generateImages()} should be called after this.
     */
    ImageCollection(Params params) throws IllegalArgumentException {
        params.verify();
        imageStack = new ArrayList<>();
        this.params = params;
    }

    /**
     * Randomly generates images based on the parameters passed to the constructor.
     *
     * @throws ArithmeticException If generation fails due to non-intersection of circles - see {@code
     *                             Circle.circleCircleIntersect}
     */
    void generateImages() throws ArithmeticException {
        if (params.seed.use) {
            RngUtility.rng = new Random(params.seed.value());
        }

        imageStack.clear();
        for (int i = 0; i < params.nImages.value(); i++) {
            FiberImage image = new FiberImage(params);
            image.generateFibers();
            image.smooth();
            image.drawFibers();
            image.applyEffects();
            imageStack.add(image);
        }
    }

    /**
     * @return {@code true} if there are no images in the stack; {@code false} otherwise
     */
    @SuppressWarnings("BooleanMethodIsAlwaysInverted")
    boolean isEmpty() {
        return imageStack.isEmpty();
    }

    FiberImage get(int i) {
        return imageStack.get(i);
    }

    /**
     * @return A copy to ith {@code BufferedImage}
     */
    BufferedImage getImage(int i) {
        return get(i).getImage();
    }

    /**
     * @return The number of images in the stack
     */
    int size() {
        return imageStack.size();
    }
}