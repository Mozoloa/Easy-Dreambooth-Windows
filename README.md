# Index

- [Index](#index)
  - [  Introduction](#--introduction)
    - [**⚠️ WARNING**](#️-warning)
- [ Setup](#-setup)
- [ Prepare the training data](#-prepare-the-training-data)

## <a name="Introduction"></a>  Introduction
This is repo is based off [Joe Penna's Dreambooth Repo](https://github.com/JoePenna/Dreambooth-Stable-Diffusion)

I originally created this fork to simplify local dreambooth training on windows for GPUs with more than 24GB of VRAM. **I found that using the countless optimized versions of dreambooth and lora never matched the quality of result you get with the original implementation, by far** and I was tired of paying for vast.ai 3090s (when I have one at home) and having to set everything up from scratch everytime.

### **⚠️ WARNING**

- This is only for training face portraits of humans, altho you might be able to fiddle around and train other things
- AFAIK You can **only run this on a GPU with 24GB of VRAM or more**(e.g. 3090) on **Windows 10 or 11 x64**. Making sure this is the *only* program running can greatly help the speed and stability.
- It works best with variants of Stability's Stable Diffusion 1.5 model
- This implementation does not fully implement Google's ideas on how to preserve the latent space:
  - Most images that are similar to what you're training will be shifted towards that.
  - e.g. If you're training a person, all people will look like you. If you're training an object, anything in that class will look like your object.
- The provided notebook has a pruner that crunches the final model down to `~2gb`, this does not affect quality
- Follow the instructions bellow carefully


# <a name="setup"></a> Setup
1. Download and install [miniconda](https://repo.anaconda.com/miniconda/Miniconda3-latest-Windows-x86_64.exe), during the install don't forger to add conda to PATH
2. Download [GIT](https://github.com/git-for-windows/git/releases/download/v2.40.0.windows.1/Git-2.40.0-64-bit.exe) and don't forget to add it to PATH during the install as well
3. Open windows explorer and navigate to where you want to install this UI
4. Click in the explorer address bar from within this folder, delete the existing path and type ***powershell*** and press `Enter`
5. In the Powershell terminal, type `git clone https://github.com/Mozoloa/Easy-Dreambooth-Windows`, 
6. Open the newly created folder named ***Easy-Dreambooth-Windows***
7. Right click ***UI.ps1*** and **"Run with Powershell"**
8. Wait for it to install all that's needed, this can take a while

# <a name="prepare-the-training-data"></a> Prepare the training data
*A detailed guide*
1. Find 8 to 20 pictures of your subject and follow those very important directions:
   1. All pictures need to be cropped to 512x512 pixels
   2. All pictures need to be saved as .png files
   3. The picture folder must only contain said pictures
   4. You can't use an odd number of pictures, **it must be even**
   5. Focus on having a diverse set of pictures, where all that stays in between them is what fundamentaly constitutes your subject:
      1. Backgrounds must not repeat between pics
      2. Clothes must not repeat between pics
      3. Use as much lighting variation as possible
      4. Use high quality pictures, avoid overly grainy and blurry pics
      5. Facial expressions must not be too wild, but variety is welcome
      6. Avoid wide angle distorted pics like close selfies
      7. I wouldn't bother with full body shots unless it's very important, focus on portraits and close ups
      8. Avoid major occlusions like hands and remove any other person from the pictures
2. [Find your celebrity doppleganger by uploading some of your subject pics to this website](https://starbyface.com/)
   1. This actually helps as celebrities literally are in the "cool" zone of the latent space
   2. **Your celebrity doppleganger must exist in the model you'll use for the training**, try prompting their name in your prefered stable diffusion generation program, if they're faithfully generated then you're good, else find another one, it's okay if they only vaguely resemble you as long as there's a little something, and the model you'll use to resume training can generate them faithfully.
   3. Once you've found their name, remove the space and caps and use it as your **Token**. ***i.e. your celebrity doppleganger is Joe Penna, you'll then use "joepenna" as a token***