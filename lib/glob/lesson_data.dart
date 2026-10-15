class LessonData {
  static List<Map<String, dynamic>> modules = [
    {
      "pages": [
        {
          "caption": "Jaca Logo",
          "title": "What is Java?",
          "content": "Java is a high-level, object-oriented programming language developed by Sun Microsystems in 1995. It is designed to be simple, secure, and platform-independent.\n\nJava is one of the most popular programming languages used for developing applications such as desktop software, mobile apps, web systems, and games.\n\nBecause of its versatility and reliability, Java is widely taught in schools and universities around the world.\n\nKey Points:\nDeveloped by Sun Microsystems\nCreated by James Gosling\nReleased in 1995\nObject-Oriented Programming Language\nPlatform Independent",
          "image": "lesson-asset-1780220699001-bxfotp5q.png",
        },
        {
          "caption": "The father of java",
          "title": "History of Java",
          "content": "Java was created by James Gosling and a team of developers at Sun Microsystems.\n\nThe project began in 1991 and was originally intended for interactive television devices.\n\nHowever, Java later became one of the most popular programming languages for computers and the internet.",
          "image": "lesson-asset-1780220699005-c0cuuvwe.jpg",
        },
        {
          "caption": "Java Time line",
          "title": "Timeline of Java",
          "content": "1991 – Java project started\n1995 – Java officially released\n2009 – Oracle acquired Sun Microsystems\nPresent – Java remains one of the world's leading programming languages",
          "image": "lesson-asset-1780220699005-rnscq7je.webp",
        },
        {
          "caption": null,
          "title": "Why Learn Java?",
          "content": "Java is an excellent programming language for beginners because it introduces important programming concepts that are used in many other languages.\n\nLearning Java helps students develop logical thinking, problem-solving skills, and computational thinking.\n\nJava is also widely used in the industry, making it a valuable skill for future careers in Information Technology and Software Development.\n\nBenefits of Learning Java:\nEasy to understand syntax\nUsed worldwide\nStrong community support\nCreates different types of applications\nBuilds programming foundations",
          "image": "",
        },
        {
          "caption": "",
          "title": "Main Features",
          "content": "Java has several important features:\n\nSimple\nSecure\nRobust\nPortable\nObject-Oriented\nMultithreaded\n\nThese features make Java suitable for creating reliable application",
          "image": "lesson-asset-1780220699001-cjedqcsv.jpg",
        },
        {
          "caption": "Simple Example",
          "title": "Object-Oriented Programming",
          "content": "Java follows the Object-Oriented Programming (OOP) approach.\n\nOOP organizes programs using:\nClasses\nObjects\nMethods\nAttributes\n\nThis makes programs easier to manage and maintain.",
          "image": "lesson-asset-1780220699001-iz29qz85.png",
        },
      ],
      "title": "Introduction to Java",
      "description": "Learn Java, its history, main features, and object-oriented programming.",
      "passingScore": 80,
      "timeLimit": 1200,
      "questions": [
        {
          "question": "What is Java?",
          "options": [
            "A high-level object-oriented language",
            "A spreadsheet",
            "An operating system",
            "A database only",
          ],
          "answer": 0,
        },
        {
          "question": "Who created Java?",
          "options": [
            "Bill Gates",
            "James Gosling",
            "Tim Berners-Lee",
            "Dennis Ritchie",
          ],
          "answer": 1,
        },
        {
          "question": "When was Java officially released?",
          "options": ["1985", "1991", "1995", "2005"],
          "answer": 2,
        },
        {
          "question": "Which company originally developed Java?",
          "options": ["Apple", "Microsoft", "IBM", "Sun Microsystems"],
          "answer": 3,
        },
        {
          "question": "What does platform-independent mean?",
          "options": [
            "Java runs only on one computer",
            "Java code can run on different supported platforms",
            "Java cannot run mobile apps",
            "Java does not need instructions",
          ],
          "answer": 1,
        },
        {
          "question": "Which approach does Java follow?",
          "options": [
            "Object-oriented programming",
            "Only manual computation",
            "Only spreadsheet formulas",
            "No programming approach",
          ],
          "answer": 0,
        },
        {
          "question": "Which item is used to organize an OOP program?",
          "options": [
            "Slides",
            "Tables only",
            "Classes and objects",
            "Folders only",
          ],
          "answer": 2,
        },
        {
          "question": "Which is a feature of Java?",
          "options": [
            "Only one platform",
            "No security features",
            "Cannot use threads",
            "Multithreading",
          ],
          "answer": 3,
        },
        {
          "question": "Why learn Java?",
          "options": [
            "It builds programming foundations",
            "It replaces all hardware",
            "It never needs debugging",
            "It cannot be used in industry",
          ],
          "answer": 0,
        },
        {
          "question": "Which is a common Java application?",
          "options": [
            "Paper filing only",
            "Desktop and mobile software",
            "Drawing without a computer",
            "Manual bookkeeping only",
          ],
          "answer": 1,
        },
      ],
    },
    {
      "pages": [
        {
          "caption": null,
          "title": "What is Programming?",
          "content": "Programming is the process of creating instructions that tell a computer what to do. These instructions are called code and are written using a programming language such as Java.\n\nProgrammers use code to solve problems, automate tasks, and develop software applications. Every program follows a logical sequence of steps to produce the desired output.\n\nKey Points\nProgramming gives instructions to a computer.\nPrograms are written using programming languages.\nJava is one of the most popular programming languages.\nProgramming helps solve real-world problems.",
          "image": "",
        },
        {
          "caption": "example code",
          "title": "Variables and Data Types",
          "content": "What is a Variable?\n\nA variable is a storage location used to hold data in a program.\n\nVariables allow programmers to store information that can be used and changed while the program runs.",
          "image": "lesson-asset-1780222138592-l5c9rl63.png",
        },
        {
          "caption": "example code",
          "title": "Common Data Types in Java",
          "content":
              "Choosing the correct data type helps manage memory efficiently.",
          "image": "lesson-asset-1780222138592-8hglb0pv.png",
        },
        {
          "caption": null,
          "title": "Using Variables in Output",
          "content": "public class Student {\n public static void main(String[] args) {\n String name = \"Maria\";\n int age = 16;\n\n System.out.println(name);\n System.out.println(age);\n }\n}\n\nOutput:\nMaria\n16",
          "image": "",
        },
        {
          "caption": "example code",
          "title": "Components of a Java Program",
          "content": "A Java program is made up of several important parts:\nClass\nMain Method\nStatements\nVariables\nComments\n\nEach component has a specific purpose and works together to make the program function correctly.",
          "image": "lesson-asset-1780222138592-aqf5o41a.png",
        },
        {
          "caption": "example picture",
          "title": "Operators in Java",
          "content": "Arithmetic Operators\n\nArithmetic operators perform mathematical operations.\n\nExample\nint sum = 10 + 5;\nSystem.out.println(sum);\n\nOutput= 15",
          "image": "lesson-asset-1780222138596-qzjx3hmn.png",
        },
        {
          "caption": "example picture",
          "title": "Subtopic 2",
          "content": "Comparison Operators",
          "image": "lesson-asset-1780222138597-kt4uv5ws.png",
        },
        {"caption": null, "title": "Subtopic 3", "content": "", "image": ""},
        {
          "caption": null,
          "title": "Input, Process, and Output (IPO)",
          "content": "Input, Process, and Output (IPO)\nMost computer programs follow the IPO Model:\nInput → Data entered by the user\nProcess → Computation or decision performed by the program\nOutput → Result displayed to the user\n\nExample\nInput: 5 and 10\nProcess: Add the numbers\nOutput: 15",
          "image": "",
        },
        {
          "caption": "example code",
          "title": "Subtopic 1The if Statement",
          "content": "The if Statement",
          "image": "lesson-asset-1780222138592-11p2u5jr.png",
        },
        {
          "caption": "example code",
          "title": "if-else Statement",
          "content": "The if-else statement provides two possible outcomes.",
          "image": "lesson-asset-1780222138592-110lcse2.png",
        },
        {
          "caption": "example code",
          "title": "Writing and Running Java Programs",
          "content": "Before running a Java program, programmers must:\nWrite the code.\nSave the file.\nCompile the program.\nRun the program.\n\nThe Java compiler checks for errors before the program is executed.",
          "image": "lesson-asset-1780222138592-o9h2agbg.png",
        },
      ],
      "title": "Basic Programming in Java",
      "description": "Explore variables, data types, operators, conditions, and running Java programs.",
      "passingScore": 80,
      "timeLimit": 1200,
      "questions": [
        {
          "question": "What is programming?",
          "options": [
            "Buying hardware",
            "Creating instructions for a computer",
            "Printing without code",
            "Replacing a monitor",
          ],
          "answer": 1,
        },
        {
          "question": "What is a variable?",
          "options": [
            "A fixed screen size",
            "A network cable",
            "A storage location for data",
            "A type of printer",
          ],
          "answer": 2,
        },
        {
          "question": "Which Java type stores a whole number?",
          "options": ["int", "boolean", "String", "char"],
          "answer": 0,
        },
        {
          "question": "Which Java type can store a name such as Maria?",
          "options": ["int", "double", "boolean", "String"],
          "answer": 3,
        },
        {
          "question": "What does System.out.println(name) do?",
          "options": [
            "Deletes the variable",
            "Displays its value",
            "Compiles a class",
            "Reads a password",
          ],
          "answer": 1,
        },
        {
          "question": "What is 10 + 5?",
          "options": ["15", "5", "50", "105"],
          "answer": 0,
        },
        {
          "question": "What does IPO stand for?",
          "options": [
            "Internet Program Object",
            "Integer Print Output",
            "Input Process Output",
            "Input Package Operator",
          ],
          "answer": 2,
        },
        {
          "question": "What does an if statement do?",
          "options": [
            "Always repeats forever",
            "Saves every file",
            "Changes the language",
            "Runs code when a condition is true",
          ],
          "answer": 3,
        },
        {
          "question": "What does an if-else statement provide?",
          "options": [
            "No possible outcome",
            "Two possible branches",
            "Only a class name",
            "Only a data type",
          ],
          "answer": 1,
        },
        {
          "question": "What checks Java code before it runs?",
          "options": [
            "The compiler",
            "The mouse",
            "The screen",
            "The keyboard",
          ],
          "answer": 0,
        },
      ],
    },
    {
      "pages": [
        {
          "caption": null,
          "title": "Introduction to Advanced Java Programming",
          "content": "Introduction to Advanced Java Programming\n\nAdvanced Java Programming focuses on creating more efficient, organized, and reusable programs. Instead of writing simple statements, programmers learn techniques that reduce repetition and improve program structure.\n\nThese concepts allow developers to create larger and more complex applications while maintaining readability and efficiency.\n\nKey Points\nImproves programming efficiency\nReduces repetitive code\nEncourages code reusability\nHelps develop larger applications\nIntroduces Object-Oriented Programming (OOP)",
          "image": "",
        },
        {
          "caption": null,
          "title": "Loops in Java",
          "content": "What are Loops?\n\nLoops allow a program to repeat a set of instructions multiple times without rewriting the code.\n\nLoops are useful when performing repetitive tasks such as displaying numbers, processing records, or validating user input.\n\nTypes of Loops\nfor Loop\nwhile Loop\ndo-while Loop",
          "image": "",
        },
        {
          "caption": "example code",
          "title": "The for Loop",
          "content": "The for loop is commonly used when the number of repetitions is known.",
          "image": "lesson-asset-1780222535621-rxyz2web.png",
        },
        {
          "caption": null,
          "title": "Why Learn Advanced Java Concepts?",
          "content": "As programs become larger, managing code becomes more difficult. Advanced Java concepts help programmers organize their code and solve problems more effectively.\n\nBy learning loops, arrays, methods, and classes, students can write programs that are easier to understand, maintain, and expand.\n\nBenefits\nBetter problem-solving skills\nImproved program organization\nFaster program development\nEasier debugging and maintenance",
          "image": "",
        },
        {
          "caption": "example code",
          "title": "What is an Array?",
          "content": "An array is a collection of multiple values stored under a single variable name.\n\nArrays help programmers organize and manage related data efficiently.",
          "image": "lesson-asset-1780222535621-3vlbctno.png",
        },
        {
          "caption": "example code",
          "title": "Accessing Array Elements",
          "content":
              "Each element in an array has an index number starting from 0.",
          "image": "lesson-asset-1780222535621-jdvyl73o.png",
        },
        {
          "caption": null,
          "title": "Real-World Applications of Advanced Java",
          "content": "Advanced Java concepts are used in:\n\nStudent Information Systems\nBanking Applications\nOnline Shopping Systems\nMobile Applications\nEducational Software\nGame Development\n\nThese applications rely on structured programming techniques to handle large amounts of data and user interactions.",
          "image": "",
        },
        {
          "caption": "example code",
          "title": "What is a Method?",
          "content": "A method is a block of code that performs a specific task. Methods help reduce repetition and improve code organization.",
          "image": "lesson-asset-1780222535621-b6cdoumy.png",
        },
        {
          "caption": "example code",
          "title": "Introduction to Classes and Objects",
          "content": "Java is an Object-Oriented Programming language.\n\nA class serves as a blueprint, while an object is an instance created from that blueprint.",
          "image": "lesson-asset-1780222535621-4y72gcdj.png",
        },
      ],
      "title": "Advanced Programming in Java",
      "description": "Learn loops, arrays, methods, classes, and objects.",
      "passingScore": 80,
      "timeLimit": 1200,
      "questions": [
        {
          "question": "Why use loops?",
          "options": [
            "To repeat instructions",
            "To delete every variable",
            "To replace all classes",
            "To stop all programs",
          ],
          "answer": 0,
        },
        {
          "question":
              "Which loop is useful when the repetition count is known?",
          "options": ["A class", "A for loop", "An array", "A comment"],
          "answer": 1,
        },
        {
          "question": "Which is another Java loop?",
          "options": ["screen", "folder", "while", "packageName"],
          "answer": 2,
        },
        {
          "question": "What is an array?",
          "options": [
            "One comment only",
            "A method name",
            "A monitor setting",
            "A collection of values under one name",
          ],
          "answer": 3,
        },
        {
          "question": "What is the index of the first array element?",
          "options": ["1", "0", "-1", "10"],
          "answer": 1,
        },
        {
          "question": "What is a method?",
          "options": [
            "A block of code that performs a task",
            "A screen color",
            "A hard disk",
            "A random filename",
          ],
          "answer": 0,
        },
        {
          "question": "What is a class?",
          "options": [
            "A compiled image",
            "An array index",
            "A blueprint for objects",
            "A keyboard shortcut",
          ],
          "answer": 2,
        },
        {
          "question": "What is an object?",
          "options": [
            "Only a text comment",
            "Only a file extension",
            "Only an array length",
            "An instance of a class",
          ],
          "answer": 3,
        },
        {
          "question": "Which concept helps reduce repeated code?",
          "options": [
            "Methods",
            "Longer filenames",
            "More blank lines",
            "Larger screens",
          ],
          "answer": 0,
        },
        {
          "question": "Where are advanced Java concepts used?",
          "options": [
            "Only in printed books",
            "Student information and banking systems",
            "Only in drawings",
            "Nowhere in software",
          ],
          "answer": 1,
        },
      ],
    },
  ];
}
