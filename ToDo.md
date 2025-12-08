AI Planing prompt

Please help me design and develop an iPhone App. Let's start by planing out our steps, don't write any code, let's think about it first and lay out a plan.

I want to design a language learning app for learning Chinese as an English speaker.

Main screen will show 2 buttons : "New phrase" and "Practice"

New Phrase button
-----------------
This will open a blank screen with a bouncing circle or some animation to show that the app is listening. The user is invited to speak into the microphone. The user will speak a phrase in english that they want to learn. After saying the phrase in English, the user will tap the screen to end recirding. The app will use this recording to perform the following actions:
1 - Speech to text transcription
2 - Connect to an AI service to perform translation from English into Chinese based on the most coloquial/informal/everyday speech version of the phrase. (I have a pro account with Claude so we can probably use Anthropic API keys for this)
3 - It will show this phrase to the user in both pinyin and hanzi
4 - It will Speak this phrase to the user in Chinese (so we need some sort of text to speach ability in Chinese)
5 - It will confirm that the phrase has been succesfully saved
6 - It will go back to the main screen

Practice button
---------------
This will open a new screen where the user can perform spaced repetition of the phrases that have been saved via the "new phrase" flow.
Saved phrases will be shown one by one based on their spaced repetition scheduling.
We need a an algorithm to assign probabilities of being shown to each phrase based on the last time it was shown and how difficult the user found it to recall.
So then, the user is shown a phrase in English, they try to recall and when they think they have it, they will be shown the pinyin, and have a voice speak the text out loud in Chinese (here again we need that same text to speech tool). After this, when the user taps again, the screen should show the hanzi character one by one - one per tap, until the whole phrase is shown. At this point the buttons will show up "Hard" "Easy" in order to record haw hard or easy recall was. As soon as the user picks an option, the app should record this selection, update the word probabilities under the hood and show the next english phrase for practice.
There should be a "Back to Home" button somewhere on this screen to go back to the main screen.


That is it.

Let's discuss what tools we might need to make all of this happen.
I am happy with having most of this run on-device, no need to sync flashcard decks online for later retrieval or usage in a different interface - so this makes storage easier since it will be all local.

However, all the other tools, for microphone listening, transcription, text to speech, ai integration and spaced repetition algorithm integration - we need to make some decisions.




Hard/Easy granularity - Do you want just 2 buttons, or would you prefer 3-4 options (Again / Hard / Good / Easy) like Anki? More granularity = better algorithm tuning.
Audio recording storage - Do you want to save the original English audio recordings, or just the transcribed text? (Storage vs. potential future feature to replay your voice)
Offline mode - The translation step requires internet (Claude API). Is that acceptable, or do you want some offline fallback?
Chinese voice quality - Should we test Apple's built-in TTS first and upgrade if needed, or go straight to a premium option?
Error handling for translation - What if the API call fails? Retry? Let user edit manually?

1 - Hard / Easy is what I find works best for me, so yes, let's keep it at 2 buttons
2 - No need to store original English recording - we use this to transcribe and then discard it - if it is possible to do without even storing it temporarily, then perfect, we don't need it
3 - Full online is ok for now - I might think about offline fallback in the future
4 - Let's go straight for it with the built in Apple text to speech if you say it's probably good enough. We will upgrade later if it turns out not to be the case
5 - We should add a button to retry. Even if the translation worked, I would like to be able to retry the transation. Somethines the AI might return a slightly different version on another attempt. So this retry button would be visible both if it failed or if it succeeded.