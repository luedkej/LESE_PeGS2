
# Read the example image from the PeGS2.0 solver to check why their particle detection image is grey 
# when they are working with the red channel in the particle_detection

import cv2
import numpy as np
import matplotlib.pyplot as plt

def main():
    print("Hello Sunshine :)")
    
    image_dir   = r'C:\Users\Jakob\ETH\Reasearch_Assistance_LESE\repos\LESE_PeGS2\jakob\images'
    image_name  = r'\IMG_0004.JPG'

    image = image_dir + image_name
    image_bgr = cv2.imread(image, 1)
    image_rgb = cv2.cvtColor(image_bgr, cv2.COLOR_BGR2RGB)
    shape = image_rgb.shape
    dtype = image_rgb.dtype
    
    basic_inspection = (shape, dtype)
    print(basic_inspection)
    
    plt.imshow(image_rgb)
    # plt.show()
    
    image_red   = image_rgb[:,:,0]
    image_green = image_rgb[:,:,1]
    image_blue  = image_rgb[:,:,2]
    
    # image_red_grey = np.dot(image_rgb[...,:3], [0.2989, 0.5870, 0.1140])
    
    image_red_2 = np.array(image_red) - 0.10*np.array(image_green) - 0.25*np.array(image_blue)
    print(type(image_red))
    print(image_green[0].shape)
    
    plt.imshow(image_red, cmap='gray')
    plt.savefig(image_dir + r'\red_channel')
    # plt.show()
    plt.imshow(image_red_2)
    plt.savefig(image_dir + r'\red_channel_2')
    # plt.show()
    plt.imshow(image_green)
    plt.savefig(image_dir + r'\green_channel.png')
    plt.imshow(image_blue)
    plt.savefig(image_dir + r'\blue_channel.png')
    
    # plt.imshow(image_red_grey, cmap='grey')
    # plt.imshow(image_rgb, cmap='grey')
    # plt.show()
    
if __name__ == "__main__":
    main()