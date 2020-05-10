# Image resizing app

This project aims to crop and resize an image and store the resulting images to Amazon S3. It is designed to be deployed as an AWS Lambda function.

## Behaviour

The Lambda function parses the incoming event - which should contain an image file and a key in a multipart/form-data - and manipulates the image it received.  
The function will asynchronously create three cropped versions of the provided image: 
- a first image with a maximum size of 456x456 pixels.
- a second image with a maximum size of 200x200 pixels.
- a third image with a maximum size of 75x75 pixels.

The function does not enlarge an image if it is smaller than one of these boundaries and will send the image as is.  
This means providing the function with a 300x160 pixels image will result in: 
- the same 300x160 pixels image.
- a cropped image with a 200x160 pixels aspect ratio.
- a cropped square with a size of 75x75 pixels.

Once an image is correctly created, the function will asynchronously send it to the configured S3 bucket.

## Environment variables

`S3_BUCKET`: the name of the S3 bucket to send the images to.