# BeatBeat

## Description

This project is about visualizing sound pulses on RGB LED Matrix. We use Google Speech API to convert
speech to text, use it as query parameter for SoundCloud Api, and finally playback the recommended song using Gstreamer player, and at the same time show visualization on RGB LED Matrix.

Until now, we have achieved first milestone of simulating the visualization using [Cava](http://karlstav.github.io/cava/) on raspberry pi's terminal.
Showing actual output on RGB Led Matrix (32x32) is work in progress.

#### Libraries and Hardware Used

1. Raspberry Pi 2
2. [Google Speech API](https://cloud.google.com/speech/) (Python library)
3. Cava
4. Gstreamer player
5. [RGB LED Matrix (32x32)](https://www.adafruit.com/product/607)
6. Bluemoon USB Mic
7. Speakers

## How to run this code

### Setup

Before running these samples perform the steps:

* Clone this repo
    ```
    git clone https://github.com/DjangoGirlsSeoul/BeatBeat.git
    cd BeatBeat
    ```

* Create a [virtualenv][virtualenv]
    ```
    virtualenv env
    source env/bin/activate
    ```

### Install the dependencies
```bash
pip install -r requirements.txt
```

### Google Cloud Speech API

### Prerequisites

### Enable the Speech API

If you have not already done so,
[enable the Google Cloud Speech API for your project](https://console.cloud.google.com/apis/api/speech.googleapis.com/overview).
You must be whitelisted to do this.


### Set Up to Authenticate With Your Project's Credentials

The code uses a service account for OAuth2 authentication.
So next, set up to authenticate with the Speech API using your project's
service account credentials.

Visit the [Cloud Console](https://console.cloud.google.com), and navigate to:
`API Manager > Credentials > Create credentials >
Service account key > New service account`.
Create a new service account, and download the json credentials file.

Then, set
the `GOOGLE_APPLICATION_CREDENTIALS` environment variable to point to your
downloaded service account credentials before running this example:

    export GOOGLE_APPLICATION_CREDENTIALS=/path/to/your/credentials-key.json

If you do not do this, the REST api will return a 403. The streaming sample will
just sort of hang silently.

See the
[Cloud Platform Auth Guide](https://cloud.google.com/docs/authentication#developer_workflow)
for more information.

### SoundCloud
Obtain API Key (client id) from here[https://developers.soundcloud.com/] and add to `speech_streaming.py`

### Troubleshooting

#### PortAudio on OS X

If you see the error

    fatal error: 'portaudio.h' file not found

Try adding the following to your ~/.pydistutils.cfg file,
substituting in your appropriate brew Cellar directory:

    include_dirs=/usr/local/Cellar/portaudio/19.20140130/include/
    library_dirs=/usr/local/YourUsername/homebrew/Cellar/portaudio/19.20140130/lib/

## Run the Code

* To run the `speech_streaming.py` code:

    ```sh
    $ python speech_streaming.py
    ```

    You should see a response with the transcription result and Sound cloud track result.


    The code will run in a continuous loop, printing the data and metadata
    it receives from the Speech API, which includes alternative transcriptions. Say "stop" to exit the loop.

    Note that the `speech_streaming.py` sample does not yet support python 3, as
    the upstream `grpcio` library's support is [not yet
    complete](https://github.com/grpc/grpc/issues/282).

* To see the audio visualization simulation. `git clone` the [cava respository](https://github.com/karlstav/cava) and run it in a new terminal.


### Deactivate virtualenv

```
deactivate
```

### TO-DO

* Instead of showing output throug Cava, our goal is to show sound visualization on [RGB LED Matrix](https://www.adafruit.com/product/607)
