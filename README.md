# overview

This script deploys the default training analysis model from Azure Cognitive Services Custom Vision API. This model works with the semisupervised framework to marshal the vision API and return the JSON results of the analysis.  The module can be configured to perform any of the vision analysis services by setting the appropriate environment variable.  Note, the installation script only sets up Azure to accept your Python model.  To actually use your Python model you have to deploy your Python code to your Azure function.  Using VS Code to deploy you model is outlined below.

Start by signing up for a free cognitive services account <https://azure.microsoft.com/en-us/try/cognitive-services/> if you do not already have one.  Then log into the Cognitive Services custom model project management portal, it is separate from the Azure Portal, and set up your project.  The portal can be found here: <https://www.customvision.ai>

Next, upload both of the powershell scripts from the imageAnalysisModel and the semisupervisedFramework, .ps1 files you will find in the solutions directories, to Azure to your azure subscription.  This article
shows how to upload and run powershell scripts in Azure:
<https://www.ntweekly.com/2019/05/24/upload-and-run-powershell-script-from-azure-cloud-shell/>

You can test the sample function using a public image simply pass in 'test' as your file name to be analyzed and the model will analyze an image from wikipedia, the URL will look something like this: https://{the name of your function app}.azurewebsites.net/{the name of your function}/?name=test or
<https://branddetectionapp.azurewebsites.net/api/detectbrand/?name=test>

If you want to perform custom model development in Python, you will need to complete the following steps to prepare your python development environment:

Set up your VS Code python environment.
Start by reading this document: <https://docs.microsoft.com/en-us/azure/azure-functions/functions-create-first-function-python> then this document: <http://www.roelpeters.be/using-python-in-azure-functions/>

Then install required software:

- install VS Code from here: <https://code.visualstudio.com/Download>
- install Python from here: <https://www.python.org/downloads/windows/>
    note as of this writing, 7/15/19, azure functions only supports python 3.6.x so make sure and pick that version and if your OS is 64 bit pick the 64 bit version or it can create path issues.
- install node.js from here: <https://nodejs.org/en/download/>
- install the Docker client from here: <https://docs.docker.com/docker-for-windows/install/>

Now before you do anything, you want to avoid environment hell, so read this on working with virtual environments in VS Code: <https://code.visualstudio.com/docs/python/environments.>  The key is making sure when you select an environment in VS Code the environment is activating.  You will know as the begining of the line in the command prompt lists the name of the virtual environment that is active in green.  If there is no grean name then you are working in the default environment.  You cannot run this project in the default (also known as base) environment because Azure functions requires a virtual environment by default.  You can turn this off but it is generally a bad idea.

Start VS Code and open a terminal.  From there run the following commands:
<<<<<<< HEAD

- install Azure Functions Core Tools from here: npm i -g azure-functions-core-tools --unsafe-perm true  For more information see <https://github.com/Azure/azure-functions-core-tools#installing>

- "pip install -azure-functions" to install azure functions core tools into VS Code.  This enables you to work with azure functions from within VS Code directly enabling things like deploy.

- "npm install -g azure-functions-core-tools" to install azure functions core tools into VS Code.  This enables you to work with azure functions from within VS Code directly enabling things like deploy.
- "pip install requests" to install http handling into VS Code.  This will allow you to work with HTTP requests which is the protocol used to communicate between the framework and the model.
- Decide which type of model you want to install Static or Trained: install Azure Computer Vision:
    "pip install azure-cognitiveservices-vision-customvision" for custom
or
    "pip install azure-cognitiveservices-vision-computervision" for static

    This will enable you to call the approprate vision services from your modeling

Then click on the extension icon on the far left in VS Code and add these VS Code extensions:

- Python
- Azure Account
- Azure Functions

Now log into Azure from VS Code: <https://www.ntweekly.com/2018/01/10/connect-microsoft-azure-directly-visual-studio-code/>

Now you click on the Azure plug in icon on the left of your VS Code environment and open your subscription then right click on your project and select 

Now you are ready to start coding.  Start by running this Python Azure Function quick start.  It will provide a very simple function that takes in a name parameter and returns a hello response.  You will then be able to add your code to this function and start deploying and running it.
<https://docs.microsoft.com/en-us/azure/cognitive-services/computer-vision/quickstarts/python-analyze>

The short sample which calls the static Azure Vision Services image analysis web service uses the vanilla
code generated by the quick start and adds the ability to call the vision API via http, updates the analysis JSON with the average confidence for the target brand, 'Microsoft' as a root key and puts the updated JSON response from the analysis service into the function response for processing by the semisupervised framework.

Once you have the quick start code running you will need to add these imports to the top of your python code in addition to the lines quick start added to your code:

- import os
- import json
- import requests
- from azure.cognitiveservices.vision.computervision import ComputerVisionClient
- from azure.cognitiveservices.vision.computervision.models import VisualFeatureTypes
- from msrest.authentication import CognitiveServicesCredentials
- from io import BytesIO

Note: If you are using a Jupyter notebook, include the following lines.
%matplotlib inline
import matplotlib.pyplot as plt
from PIL import Image

Finally, if you want to debug locally you will need to read this article about how to set up local debugging.  <https://docs.microsoft.com/en-us/azure/azure-functions/functions-run-local>

Long running fucntions ********* need to see if there is a response time limitation on functions and advise how to handle this in the model python.************
