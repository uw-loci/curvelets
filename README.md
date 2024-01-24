# Curvelet-Transform based fibrillar collagen quantification (CurveAlign and CT-FIRE)
This software package includes two tools, i.e. CurveAlign(1-3) and CT-FIRE(4-5) for collagen fiber quantification. CurveAlign is a curvelet transform (CT)-based quantitative tool for interpreting the regional interaction between collagen and tumors by assessment of up to ~thirty fiber features, including angle, alignment, and density. CT-FIRE analyzes individual fiber metrics such as length, width, angle, and curvature. The individual fibers extracted by CT-FIRE can be imported into the CurveAlign as one of the two fiber analyse modes. The approach of CT-FIRE is described in (4), which combines the advantages of the fast discrete curvelet transform(6) for denoising images, enhancement of the fiber edge features, and the fiber extraction (FIRE) algorithm (5) for extracting individual fibers.  For now, CurveAlign should be used for bulk assessment of collagen features including angles/density and CT-FIRE for individual fiber quantification.

Since the last release in 2020, we have been adding new features, mainly including 1) Bio-Formats importer/exporter to enhance image format support; 2) auto-threshold for CT-FIRE to optionally apply different thresholds for image stack or images from different acquisition settings; 3) fiber intersection points calculation based on CT-FIRE fiber extraction; 4) ROI based fiber density analysis; 5) deep learning based cell-fiber analysis. We have started trying running python-based deep learning modules for individual cell analysis which is integrated to the MATLAB-based fiber analysis pipeline to quantify the fiber-cell/tumor interactions.  
|
|CurveAlign Example| CT-FIRE Example |
|--------|--------|
|<img src ='https://loci.wisc.edu/wp-content/uploads/sites/1939/2023/03/CurveAlign5.0_forNewWebsite.jpg'>| <img src='https://loci.wisc.edu/wp-content/uploads/sites/1939/2023/03/CT-FIRE3.0_forNewWebsite.jpg'>|

CurveAlign and CT-FIRE are licensed under the 2-Clause BSD license as described LICENSE.txt, except for some third-party code whose licenses are described in LICENSE-third-party.txt. One third-party code, CurveLab 2.1.2 MATLAB package for curvelet transform, can only be downloaded from http://www.curvelet.org/software.html. To run CurveAlign or CT-FIRE, the CurveLab needs to be downloaded and added to the Matlab searching path.

# Installation and Usage:
1) General intrunctions for downloads and installation of [CurveAlign](https://github.com/uw-loci/curvelets/wiki/Downloads-and-Installation-(CurveAlign)) or [CT-FIRE](https://github.com/uw-loci/curvelets/wiki/Downloads-and-Installation-(CTF))
   
2) Quick Manual and testimages](https://github.com/uw-loci/curvelets/releases/download/5.0/CA5.0andCTF3.0_manual_testImages.zip)
  
3) [CurveAlign FAQs](https://github.com/uw-loci/curvelets/wiki/FAQ-(CurveAlign)) and [CT-FIRE FAQs](https://github.com/uw-loci/curvelets/wiki/FAQ-(CTF))
   
4) [Initial protocol for alignment quantification](https://link.springer.com/protocol/10.1007/978-1-4939-7113-8_28)     

# References:
## CurveAlign 

1. Schneider, C.A., Pehlke, C.A., Tilbury, K., Sullivan, R., Eliceiri, K.W., and Keely, P.J. (2013). Quantitative Approaches for Studying the Role of Collagen in Breast Cancer Invasion and Progression. In Second Harmonic Generation Imaging, F.S. Pavone, and P.J. Campagnola, eds. (New York: CRC Press), p. 373.
   
2. Bredfeldt, J.S., Liu, Y., Conklin, M.W., Keely, P.J., Mackie, T.R., and Eliceiri, K.W. (2014). Automated quantification of aligned collagen for human breast carcinoma prognosis. J Pathol Inform 5.
   
3. Liu, Y., Keikhosravi, A., Mehta, G.S., Drifka, C.R., and Eliceiri, K.W. (2017). Methods for quantifying fibrillar collagen alignment. In Fibrosis: Methods and Protocols, L. Rittié, ed. (New York: Springer) p.429-451

4. Liu Y, Keikhosravi A, Pehlke CA, Bredfeldt JS, Dutson M, Liu H, Mehta GS, Claus R, Patel AJ, Conklin MW, Inman DR, Provenzano PP, Sifakis E, Patel JM, Eliceiri KW. (2020) Fibrillar collagen quantification with curvelet transform based computational methods. Front Bioeng Biotechnol 8:198.

## CT-FIRE 

5. Bredfeldt, J.S., Liu, Y., Pehlke, C.A., Conklin, M.W., Szulczewski, J.M., Inman, D.R., Keely, P.J., Nowak, R.D., Mackie, T.R., and Eliceiri, K.W. (2014). Computational segmentation of collagen fibers from second-harmonic generation images of breast cancer. Journal of Biomedical Optics 19, 016007–016007.
   
6. Stein, A. M., Vader, D. A., Jawerth, L. M., Weitz, D. A. & Sander, L. M. An algorithm for extracting the network geometry of three-dimensional collagen gels. J. Microsc. 232, 463–475 (2008).

## Fast Discrete Curvelet Transform

7. Candes, E., Demanet, L., Donoho, D. & Ying, L. Fast discrete curvelet transforms. Multiscale Model. Simul. 5, 861–899 (2006).

# Lab page links
Link to CurveAlign: http://loci.wisc.edu/software/curvealign

Link to CT-FIRE:    http://loci.wisc.edu/software/ctfire

