"""
Test suite for the CurveAlign Python API.

This module contains tests for the main API functions to ensure they work
correctly and maintain backward compatibility.
"""

import numpy as np
import pytest

import curvealign


class TestHighLevelAPI:
    """Test high-level API functions."""
    
    def test_analyze_image_basic(self):
        """Test basic image analysis functionality."""
        # Create test image
        image = np.random.rand(256, 256)
        
        # Analyze image
        result = curvealign.analyze_image(image)
        
        # Check result structure
        assert isinstance(result, curvealign.AnalysisResult)
        assert isinstance(result.curvelets, list)
        assert isinstance(result.features, dict)
        assert isinstance(result.stats, dict)
        
        # Check that we got some curvelets
        assert len(result.curvelets) > 0
        
        # Check stats
        assert 'mean_angle' in result.stats
        assert 'std_angle' in result.stats
        assert 'alignment' in result.stats
        assert 'density' in result.stats
        assert 'total_curvelets' in result.stats
    
    def test_analyze_image_with_options(self):
        """Test image analysis with custom options."""
        image = np.random.rand(256, 256)
        
        options = curvealign.CurveAlignOptions(
            keep=0.002,
            dist_thresh=50.0,
            map_std_window=12
        )
        
        result = curvealign.analyze_image(image, options=options)
        
        assert isinstance(result, curvealign.AnalysisResult)
        assert len(result.curvelets) > 0
    
    def test_batch_analyze(self):
        """Test batch analysis functionality."""
        # Create test images
        images = [np.random.rand(128, 128) for _ in range(3)]
        
        # Batch analyze
        results = curvealign.batch_analyze(images)
        
        # Check results
        assert len(results) == 3
        for result in results:
            assert isinstance(result, curvealign.AnalysisResult)
            assert len(result.curvelets) > 0


class TestMidLevelAPI:
    """Test mid-level API functions."""
    
    def test_get_curvelets(self):
        """Test curvelet extraction."""
        image = np.random.rand(256, 256)
        
        curvelets, coeffs = curvealign.get_curvelets(image)
        
        assert isinstance(curvelets, list)
        assert len(curvelets) > 0
        assert all(isinstance(c, curvealign.Curvelet) for c in curvelets)
        
        # Check curvelet properties
        c = curvelets[0]
        assert isinstance(c.center_row, int)
        assert isinstance(c.center_col, int)
        assert isinstance(c.angle_deg, float)
        assert 0 <= c.angle_deg <= 180
    
    def test_compute_features(self):
        """Test feature computation."""
        # Create some test curvelets
        curvelets = [
            curvealign.Curvelet(100, 100, 45.0, 1.0),
            curvealign.Curvelet(102, 98, 50.0, 0.8),
            curvealign.Curvelet(95, 105, 40.0, 1.2),
        ]
        
        features = curvealign.compute_features(curvelets)
        
        assert isinstance(features, dict)
        assert 'center_row' in features
        assert 'center_col' in features  
        assert 'angle_deg' in features
        assert 'weight' in features
        
        # Check feature arrays have correct length
        assert len(features['center_row']) == len(curvelets)
        assert len(features['angle_deg']) == len(curvelets)
    
    def test_visualizations(self):
        """Test visualization functions."""
        image = np.random.rand(128, 128)
        curvelets = [
            curvealign.Curvelet(50, 50, 45.0, 1.0),
            curvealign.Curvelet(75, 75, 90.0, 0.8),
        ]
        
        # Test overlay
        overlay = curvealign.overlay(image, curvelets)
        assert overlay.shape == (128, 128, 3)
        assert overlay.dtype == np.uint8
        
        # Test angle maps
        raw_map, processed_map = curvealign.angle_map(image, curvelets)
        assert raw_map.shape == image.shape
        assert processed_map.shape == image.shape


class TestTypes:
    """Test type definitions and data structures."""
    
    def test_curvelet_type(self):
        """Test Curvelet namedtuple."""
        c = curvealign.Curvelet(100, 150, 45.0, 1.5)
        
        assert c.center_row == 100
        assert c.center_col == 150
        assert c.angle_deg == 45.0
        assert c.weight == 1.5
    
    def test_options_type(self):
        """Test CurveAlignOptions dataclass."""
        options = curvealign.CurveAlignOptions(
            keep=0.002,
            dist_thresh=75.0,
            exclude_inside_mask=True
        )
        
        assert options.keep == 0.002
        assert options.dist_thresh == 75.0
        assert options.exclude_inside_mask is True
        
        # Test default values
        assert options.scale is None
        assert options.min_dist is None
        assert options.map_std_window == 24
    
    def test_boundary_type(self):
        """Test Boundary type."""
        # Test mask boundary
        mask = np.zeros((100, 100), dtype=bool)
        mask[25:75, 25:75] = True
        
        boundary = curvealign.Boundary("mask", mask)
        assert boundary.kind == "mask"
        assert boundary.data.shape == (100, 100)


class TestEdgeCases:
    """Test edge cases and error conditions."""
    
    def test_empty_image(self):
        """Test handling of empty or very small images."""
        # Very small image
        small_image = np.random.rand(10, 10)
        result = curvealign.analyze_image(small_image)
        
        # Should still return valid result structure
        assert isinstance(result, curvealign.AnalysisResult)
    
    def test_uniform_image(self):
        """Test handling of uniform (no structure) images."""
        uniform_image = np.ones((256, 256))
        result = curvealign.analyze_image(uniform_image)
        
        assert isinstance(result, curvealign.AnalysisResult)
        # Uniform image should have few or no curvelets
        assert len(result.curvelets) >= 0
    
    def test_invalid_mode(self):
        """Test error handling for invalid analysis mode."""
        image = np.random.rand(128, 128)
        
        with pytest.raises(ValueError, match="Unknown mode"):
            curvealign.analyze_image(image, mode="invalid_mode")


if __name__ == "__main__":
    pytest.main([__file__])
