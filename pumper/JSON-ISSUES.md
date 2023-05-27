#  Known BAD JSON Issues with Pumper Output:

## EXTRA LINE FEED WITHIN IMAGE FIELD


```{
    "id": "2FFBDE5B-6CEB-47EE-8E09-9D8D2F8E1F2C",
    "idx": 69,
    "timestamp": "2023-05-26 17:16:52 +0000",
    "question": "What type of services may a huckster or sheister offer?",
    "topic": "Hucksters and Sheisters",
    "hint": "Should be cautious of suspicious offers",
    "answers": ["Investment Opportunities", "Home Repair Services", "Health Supplements", "Medical Advice"],
    "correct": "Investment Opportunities",
    "explanation": "Hucksters and sheisters often offer investment opportunities that are too good to be true, so be very careful before offering money for any services.",
    "article": "https://www.investopedia.com/terms/h/huckster.asp",
    "image": "https://upload.wikimedia.org/wikipedia/commons/thumb/3/3
    9/Stolen_Credit_Card_Data_Comes_From_Malware_Installation_on_Retail_Cash_Registers.jpg/800px-Stolen_Credit_Card_Data_Comes_From_Malware_Installation_on_Retail_Cash_Registers.jpg"
  }
```
  
## RANDOM SINGLE QUOTE IN HINT FIELD
  
```{
      "id": "29292F69-490D-492F-82EA-55714F5AFF5C",
      "idx": 58,
      "timestamp": "2023-05-26 16:47:40 +0000",
      "question": "Lyndon Johnson is often referred to as 'LBJ'. What does the 'LBJ' acronym stand for?", 
      "topic": "Foreign and Domestic Pols",
      "hint": "It is a nickname for 'Lyndon".
      "answers": ["Loving Big Johnson", "Little Big Johnson", "Large But Jovial", "Lyndon Baines Johnson"],
      "correct": "Lyndon Baines Johnson",
      "explanation": "LBJ is a nickname for Lyndon Baines Johnson. It was usually given by his wife Lady Bird Johnson",
      "article": "https://blogs.smithsonianmag.com/history/the-remarkable-and-irony-filled-fate-of-lady-bird-johnsons-pet-name-lbj/",
      "image": "https://upload.wikimedia.org/wikipedia/commons/thumb/0/00/President_Lyndon_B._Johnson_%28cropped%29.jpg/800px-President_Lyndon_B._Johnson_%28cropped%29.jpg"
  }
```
  
## FIELD NAMES DO NOT HAVE SURROUNDING QUOTES !!!!!!!!!

```
{ 
    id: "1681FDE5-B722-44AA-B67B-927E2600F6FC",
    idx: 60,
    timestamp: "2023-05-26 16:53:21 +0000",
    question: "What's the most popular breed of dog?",
    topic: "Man's Best Friend",
    hint: "This breed has been America's favorite for over two decades.",
    answers: [
      "Labrador Retriever",
      "German Shepherd",
      "Pug",
      "Yorkshire Terrier"
    ],
    correct: "Labrador Retriever",
    explanation: "The Labrador Retriever has consistently held the title of most popular dog breed in America since 1991.",
    article: "https://en.wikipedia.org/wiki/Labrador_Retriever",
    image: "https://upload.wikimedia.org/wikipedia/commons/thumb/6/6d/Labrador_Retriever_adopts_kitten.jpg/1200px-Labrador_Retriever_adopts_kitten.jpg"
  }
 ```
 and
 
 ``` 
  {
  id: "1681FDE5-B722-44AA-B67B-927E2600F6FC",
  idx: 60,
  timestamp: "2023-05-26 16:53:21 +0000",
  question: "What breed of dog was bred to hunt rodents?",
  topic: "Man's Best Friend",
  hint: "This breed is also popularly known as a 'sausage dog'.",
  answers: [
    "Bulldog",
    "Beagle",
    "Poodle",
    "Dachshund"
  ],
  correct: "Dachshund",
  explanation: "The Dachshund was bred to be a hunting dog and were originally used to hunt badgers and other tunneling animals like rabbits and foxes.",
  article: "https://en.wikipedia.org/wiki/Dachshund",
  image: "https://upload.wikimedia.org/wikipedia/commons/thumb/6/61/Stuffed_Orlon_Miniature_Dachcshund_Sleep.jpg/800px-Stuffed_Orlon_Miniature_Dachcshund_Sleep.jpg"
}
```
  
## TIMESTAMP FIELD HAS LEADING BLANK (note jsonlint doesnt mind)
  
```
  {
  "id": "CF7CA5CA-C233-4149-9A86-990BEFE21649",
  "idx": 72,
  " timestamp": "2023-05-26 17:24:52 +0000",
  "question": "What is the main food of toads?",
  "topic": "Frogs - Toads - Newts",
  "hint": "Toads are carnivorous",
  "answers": ["Algae", "Insects", "Fruits", "Grass"],
  "correct": "Insects",
  "explanation": "Toads are carnivorous, so they mainly eat insects but will also consume food items such as worms, spiders, slugs, and snails.",
  "article": "https://www.nationalgeographic.com/animals/amphibians/t/toad/",
  "image": "https://static.nationalgeographic.org/files/styles/article_main_image_2200px/public/Toad_P-100117-b.jpg?w=1200&h=800&fit=crop&auto=compress&fm=jpg&q=40"
}
```
## COMPLETELY BIZARRE, ENTIRE RESPONSE IS CORRUPTED THIS WAY

```
{ 
    "id": "916B15DD-4518-4B4B-97DD-52788D4FD3EF",
    "idx": 74,
    "timestamp": "2023-05-26 17:30:52 +0000",
    "metrics": 
      "topic": "Hucksters and Sheisters"
    }
```

## "correctAnswer" instead of "correct" - entire response
```
{
  "id": "6E64610C-5F88-4445-A84A-45F944C32748",
  "idx": 77,
  "timestamp": "2023-05-26 17:38:43 +0000",
  "question": "Which of these amphibians have poison glands?",
  "topic": "Frogs - Toads - Newts",
  "hint": "One of them starts with a 'T'!",
  "answers": ["Newt", "Frog", "Toad", "Salamander"],
  "correctAnswer": "Toad",
  "explanation": "Toads are the only amphibians with poison glands. Their poison is made up of steroidal alkaloid toxins which offers them protection from predators.",
  "article": "https://www.thespruce.com/are-toads-poisonous-4083741",
  "image": "https://kids.nationalgeographic.com/content/dam/kids/photos/animals/Reptiles/Q-Z/toad-closeup.adapt.945.1.jpg"
}
```

## COMMA AT END OF ARRAY

```

{
  "id": "286F00D1-3435-4298-91C0-01819454AFEF",
  "idx": 129,
  "timestamp": "2023-05-26 19:40:00 +0000",
  "question": "What is a 'confidence trick' and why is it dangerous?",
  "topic": "Hucksters and Sheisters",
  "hint": "A psychological maneuver to exploit vulnerable people.",
  "answers": ["A scam to take advantage of people", "A way to psychologically manipulate people", "A tool to influence people behind their back", "A way to exploit vulnerable people for financial gain", ],
  "correct": "A way to exploit vulnerable people for financial gain",
  "explanation": "A confidence trick is a fraudulent activity that takes advantage of people's vulnerabilities, exploiting their trust or lack of knowledge for financial gain.",
  "article": "https://www.investopedia.com/terms/c/confidence-trick.asp",
  "image": "https://images.unsplash.com/photo-1519999482648-25049ddd37b1"
}

```

