//SPDX-License-Identifier: none

pragma solidity ^0.8.17;

library Normalize{

    error NotNormalized(bytes10 name); //0xd6d0064c
    error TooFewNumbers(uint num); //0xdc444df5
    error TooFewLetters(uint num); //0xc0492678
    error TooFewCharacters(uint num); //0xb79af97d

    /*
     * @dev Checks to make sure the name only has UTF-8 character
            0-9, a-z, and -.
     * @param name The name to check whether it is normalized or not.
     */

    function checkNormalized(bytes10 name, uint requiredNumbers, uint requiredLetters, uint minChars) internal pure{

        bool gotZero;
        bool allowed;
        bool isNumber;
        bool isLetter;

        uint numNumbers;
        uint numLetters;
        uint numChars;

        for (uint i; i < 10; ++i){


            if (i == 0){ //The first char must not be 0x00

                (allowed, isNumber, isLetter) = allowedChar(name,i);

                if (name[i] == 0x00 || !allowed){
                    revert NotNormalized(name);
                }

                if (isNumber) { 
                    ++numNumbers; 
                    ++numChars; 
                }

                if (isLetter) { 
                    ++numLetters; 
                    ++numChars; 
                }

            } else { // No spaces are allowed

                (allowed, isNumber, isLetter) = allowedChar(name,i);

                if (!allowed){
                    revert NotNormalized(name);
                }

                if (isNumber) { 
                    ++numNumbers; 
                    ++numChars; 
                }

                if (isLetter) { 
                    ++numLetters; 
                    ++numChars; 
                }

                if (name[i] == 0x00){
                    gotZero = true;
                } else {
                    if (gotZero){
                        revert NotNormalized(name);
                    }
                }
            }
        }

        if (numNumbers < requiredNumbers){
            revert TooFewNumbers(numNumbers);
        }

        if (numLetters < requiredLetters){
            revert TooFewLetters(numLetters);
        }

        if (numNumbers + numLetters < minChars){
            revert TooFewCharacters(numNumbers + numLetters);
        }
    }

    function allowedChar(bytes10 name, uint i) internal pure returns(bool allowed, bool isNumber, bool isLetter){

            if (_isNumber(name[i])){ //0-9
                allowed = true;
                isNumber = true;
            } else if (_isLetter(name[i])){ //a-z
                allowed = true;
                isLetter = true;
            } else if (name[i] == 0x2d && (i >= 1 && i <= 8)){ //-
                if ( _isNumber(name[i-1]) || _isLetter(name[i-1])){
                    allowed = true;
                    isLetter = true; // the "-" character is considered a letter
                }
            } else if (name[i] == 0x00){ 
                allowed = true;
            }

    }

    function _isLetter(bytes1 char) private pure returns (bool isLetter){
        if(char >= 0x61 && char <= 0x7a){ isLetter =true; }
    }

    function _isNumber(bytes1 char) private pure returns (bool isNumber){
        if(char >= 0x30 && char <= 0x39){ isNumber = true; }
    }

}