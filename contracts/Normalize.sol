//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

library Normalize{

    /*
     * @dev Checks to make sure the name only has UTF-8 character
            0-9, a-z, and -.
     * @param name The name to check whether it is normalized or not.
     */

    function isNormalized(bytes32 name, uint minNumbers, uint minLetters, uint minChars) internal pure returns(bool, uint){

        bool gotZero;
        bool allowed;
        bool isNumber;
        bool isLetter;

        uint numNumbers;
        uint numLetters;
        uint numChars;

        for (uint i; i < 32; ++i){

            if (i == 0){ //The first char must not be 0x00

                (allowed, isNumber, isLetter) = allowedChar(name,i);

                if (name[i] == 0x00 || !allowed){
                    return (false, 0);
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
                    return (false, 0);
                }

                if (isNumber) { 
                    ++numNumbers; 
                    ++numChars; 
                }

                if (isLetter) { 
                    ++numLetters; 
                    ++numChars; 
                }

                // If we have a 0x00, we can't have any more characters.
                if (name[i] == 0x00){
                    gotZero = true;
                } else {
                    if (gotZero){
                        return (false, 0);
                    }
                }
            }
        }

        
        bool isNormal = numNumbers < minNumbers ||
               numLetters < minLetters || 
               numChars < minChars ? false : true;

        return (isNormal, numChars);
    }

    function allowedChar(bytes32 name, uint i) internal pure returns(bool allowed, bool isNumber, bool isLetter){

            if (_isNumber(name[i])){ //0-9
                allowed = true;
                isNumber = true;
            } else if (_isLetter(name[i])){ //a-z
                allowed = true;
                isLetter = true;
            } else if (name[i] == 0x2d && (i >= 1 && i <= 8)){ //-
                // "-" is only allowed if it is not the first or last character
                // and if it is surrounded by a number or letter
                if ((_isNumber(name[i-1]) || _isLetter(name[i-1])) && 
                    (_isNumber(name[i+1]) || _isLetter(name[i+1]))){
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