
# One Time Pad Messaging App

## Brief

One time pad is a simple encryption concept, you use a unique key for each symbol you send, this is the only "information theoretically secure" encryption technique. However, this technique is entirely dependent on keeping the key secret, which is most of the challenge when establishing a connection through an untrusted network.

<br>

This technique was initially used by secret agents that would come together to share a "pad" of single use keys, hence establishing that connection in a safe way. They would use fresh keys for every message and then destroy them afterwards. What about an app where you share your pad of secret keys physically in person? Sounds fun.

<br>

This could instead be a fun feature living on top of a secure messaging app

<br>

## Features

- One time pad Encryption ✅
- Firebase messaging backend (post encryption) ✅
- Share codebook with friends via Airdrop ✅

<br>

- Embed key in share, to match against when sender detects new chat
- Typing indicator, chat last modfied indicator, message notification and message preview
- Full unicode charset, high quality random numbers
- Add codes when chat exists
- Scroll to bottom with new messages
- Local name and picture assignment

<br>

## Firebase Backend OTP App

<br>

The cipher text is written to a chat collection in Firebase, a listener fetches messages from 
the chat making them available to be decrypted. Next to add: QR codebook sharing so that two 
people can participate in the chat.

<br>

![app v2 gif](vid2.gif)


