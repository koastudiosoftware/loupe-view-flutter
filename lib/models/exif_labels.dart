//
// This model is used for mapping the EXIF tag keys to their display names.
//

class ExifLabels {
  static const Map<String, String> displayNames = {
    // --- EXIF Tags ---
    'EXIF ApertureValue': 'Aperture Value',
    'EXIF BrightnessValue': 'Brightness',
    'EXIF ColorSpace': 'Color Space',
    'EXIF ComponentsConfiguration': 'Components Configuration',
    'EXIF DateTimeDigitized': 'Date Time (Digitized)',
    'EXIF DateTimeOriginal': 'Date Time (Original)',
    'EXIF DigitalZoomRatio': 'Digital Zoom Ratio',
    'EXIF ExifImageLength': 'EXIF Image Length',
    'EXIF ExifImageWidth': 'EXIF Image Width',
    'EXIF ExifVersion': 'EXIF Version',
    'EXIF ExposureBiasValue': 'Exposure Bias',
    'EXIF ExposureMode': 'Exposure Mode',
    'EXIF ExposureProgram': 'Exposure Program',
    'EXIF ExposureTime': 'Exposure Time',
    'EXIF FNumber': 'F-Number',
    'EXIF Flash': 'Flash',
    'EXIF FlashPixVersion': 'FlashPix Version',
    'EXIF FocalLength': 'Focal Length',
    'EXIF FocalLengthIn35mmFilm': 'Focal Length in 35mm Film',
    'EXIF InteroperabilityOffset': 'Interoperability Offset',
    'EXIF ISOSpeedRatings': 'ISO Speed',
    'EXIF LightSource': 'Light Source',
    'EXIF MakerNote': 'Maker Note',
    'EXIF MaxApertureValue': 'Max Aperture',
    'EXIF MeteringMode': 'Metering Mode',
    'EXIF SceneCaptureType': 'Scene Capture Type',
    'EXIF SceneType': 'Scene Type',
    'EXIF SensingMethod': 'Sensing Method',
    'EXIF ShutterSpeedValue': 'Shutter Speed',
    'EXIF SubSecTime': 'Sub-second Time',
    'EXIF SubSecTimeDigitized': 'Sub-second Time (Digitized)',
    'EXIF SubSecTimeOriginal': 'Sub-second Time (Original)',
    'EXIF WhiteBalance': 'White Balance',

    // --- GPS Tags ---
    'GPS GPSAltitude': 'Altitude',
    'GPS GPSAltitudeRef': 'Altitude Reference',
    'GPS GPSDate': 'Date',
    'GPS GPSLatitude': 'Latitude',
    'GPS GPSLatitudeRef': 'Latitude Reference',
    'GPS GPSLongitude': 'Longitude',
    'GPS GPSLongitudeRef': 'Longitude Reference',
    'GPS GPSProcessingMethod': 'Processing Method',
    'GPS GPSTimeStamp': 'Timestamp',

    // --- Image Tags ---
    'Image DateTime': 'Date and Time',
    'Image ExifOffset': 'EXIF Offset',
    'Image GPSInfo': 'GPS Info Offset',
    'Image ImageLength': 'Image Height',
    'Image ImageWidth': 'Image Width',
    'Image Make': 'Camera Maker',
    'Image Model': 'Camera Model',
    'Image Orientation': 'Orientation',
    'Image ResolutionUnit': 'Resolution Unit',
    'Image XResolution': 'Horizontal Resolution',
    'Image YCbCrPositioning': 'YCbCr Positioning',
    'Image YResolution': 'Vertical Resolution',

    // --- Interoperability Tags ---
    'Interoperability InteroperabilityIndex': 'Interoperability Index',

    // --- Thumbnail Tags ---
    'Thumbnail Compression': 'Compression',
    'Thumbnail JPEGInterchangeFormat': 'JPEG Interchange Format',
    'Thumbnail JPEGInterchangeFormatLength': 'JPEG Interchange Format Length',
    'Thumbnail Orientation': 'Orientation',
    'Thumbnail ResolutionUnit': 'Resolution Unit',
    'Thumbnail XResolution': 'Horizontal Resolution',
    'Thumbnail YResolution': 'Vertical Resolution',

  };
}
