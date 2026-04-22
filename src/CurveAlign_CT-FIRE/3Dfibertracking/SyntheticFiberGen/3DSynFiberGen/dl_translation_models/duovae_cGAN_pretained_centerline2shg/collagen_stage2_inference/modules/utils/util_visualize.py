import numpy as np
import os
import json
from PIL import Image
import matplotlib
import matplotlib.pyplot as plt
from matplotlib.ticker import MaxNLocator
from modules.utils.util_io import as_np

def save_image(I, save_path):
    I = (I*255).astype(np.uint8)
    I = Image.fromarray(I)
    I.save(save_path)
    return save_path

def images_to_row(images):
    N, n_channel, h, w = images.shape
    vdivider = np.ones((n_channel, h, 1))
    for img_idx in range(N):
        Ii = images[img_idx]
        I = Ii if img_idx == 0 else np.concatenate((I, vdivider, Ii), axis=-1)
    return I

def save_reconstructions(stage, save_dir, model, epoch, n_samples=10):
    if stage == 1:
        # DuoVAE
        centerline = as_np(model.x)
        N = min(n_samples, centerline.shape[0])
        centerline = centerline[0:N]

        centerline_recon = as_np(model.x_recon[0:N])

        I = images_to_row(centerline)
        I_recon = images_to_row(centerline_recon)

        n_channel = 1
        hdivider = np.ones((n_channel, 1, I.shape[-1]))
        img_out = np.transpose(np.concatenate((I, hdivider, I_recon), axis=1), (1, 2, 0)).squeeze()

    elif stage == 2:
        # cGAN
        centerline = as_np(model.centerline)
        N = min(n_samples, centerline.shape[0])
        centerline = centerline[0:N]

        image_recon = as_np(model.image_recon[0:N])
        image_true = as_np(model.image[0:N])

        C = images_to_row(centerline)
        I_recon = images_to_row(image_recon)
        I_true = images_to_row(image_true)

        n_channel = 1
        hdivider = np.ones((n_channel, 1, C.shape[-1]))
        img_out = np.transpose(np.concatenate((C, hdivider, I_recon, hdivider, I_true), axis=1), (1, 2, 0)).squeeze()
    
    elif stage == 3:
        # UNet
        image = as_np(model.image)
        N = min(n_samples, image.shape[0])
        image = image[0:N]

        centerline_recon = as_np(model.centerline_recon[0:N])
        centerline_true = as_np(model.centerline[0:N])

        I = images_to_row(image)
        C_recon = images_to_row(centerline_recon)
        C_true = images_to_row(centerline_true)

        n_channel = 1
        hdivider = np.ones((n_channel, 1, I.shape[-1]))
        img_out = np.transpose(np.concatenate((I, hdivider, C_recon, hdivider, C_true), axis=1), (1, 2, 0)).squeeze()

    save_path = os.path.join(save_dir, "recon_{}.png".format(epoch))
    save_image(img_out, save_path)
    return save_path

def save_losses(save_dir, losses, epoch):
    # save loss values as json
    # json_path = os.path.join(save_dir, "losses.json")
    # with open(json_path, "w+") as f:
    #     json.dump(losses, f)

    # save loss values as plot
    plt.figure(figsize=(10, 4))
    matplotlib.rc_file_defaults()
    x_val = np.arange(1, epoch+1).astype(int)
    for loss_name, loss_val in losses.items():
        plt.plot(x_val, loss_val, linewidth=1, label=loss_name)
    leg = plt.legend(loc='upper left')
    leg_lines = leg.get_lines()
    leg_texts = leg.get_texts()
    plt.setp(leg_texts, fontsize=12)
    plt.gca().xaxis.set_major_locator(MaxNLocator(integer=True))
    plt.tight_layout()
    plt.grid()
    plt.xlabel("Epoch")
    plt.yscale("log")
    plt.title("Train loss at epoch {}".format(epoch))
    save_path = os.path.join(save_dir, "losses.png")
    plt.savefig(save_path, dpi=150, bbox_inches="tight")
    plt.close()
    return save_path
