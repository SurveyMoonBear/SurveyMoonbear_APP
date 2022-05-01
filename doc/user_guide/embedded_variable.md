# Embedded Variable
## How to add an embedded variable
Use `{{}}` with `question name` you set in the previous spreadsheet `Name (should be unique)` column in the `Description` column eg. `{{username}}`

- On Page 1, there is a `username` under the `Name (should be unique)` column (red square)

    ![image](https://user-images.githubusercontent.com/44396169/166142613-ed2332e9-5950-475b-bb88-749e9990b6e0.png)

- On Page 2, use `{{username}}` in the `Description` column

    ![image](https://user-images.githubusercontent.com/44396169/166142698-a9488eb1-21e6-4292-b963-f7fc2a752cd0.png)

- Input

    ![image](https://user-images.githubusercontent.com/44396169/166142997-fe2c44e9-b528-4aab-97e3-387b000c00b2.png)

- Preview Mode
    
    ![image](https://user-images.githubusercontent.com/44396169/166143083-b5449186-341f-4f37-b0a3-3dcb3f0a34ff.png)

- Start Mode

    ![image](https://user-images.githubusercontent.com/44396169/166143040-6b691007-d074-4018-bc2d-4bb0142aceb8.png)


## Notes
1. Supported Question Type
    - Only support **input question type** eg. Short answer, Paragraph Answer, Multiple choice, Random code
    - Not support **non-input question type** eg. Section Title, Description, Divider
2. Undefined Variable
    - If the the `question name` (`{{question_name}}`) is undefined, it will print `undefined`.
3. Preview and Start Mode
    - On preview mode, it shows the `question name`, eg. username, not the really input answer.
    - On preview mode, it can not detect defined/undefined variable because it is still under editing.
4. Limitation
    - It cannot directly show `{{}}` as character
