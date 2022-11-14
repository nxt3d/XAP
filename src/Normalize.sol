// SPDX-License-Identifier:

pragma solidity ^0.8.17;


library Normalize{

    error NotNormalized(bytes10 name);

    /*
     * @dev Checks to make sure the name only has UTF-8 character
            0-9, a-z, and -.
     * @param name The name to check whether it is normalized or not.
     */

    function checkNormalized(bytes10 name) internal pure{

        bool gotZero;

        for (uint i; i < 10; ++i){

            if (i == 0){

                if (name[i] == 0x00 || !allowedChar(name[i],i)){
                    revert NotNormalized(name);
                }

            } else {

                if (!allowedChar(name[i],i)){
                    revert NotNormalized(name);
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

    }

    function allowedChar(bytes1 char, uint i) internal pure returns(bool){

             if ((char >= 0x30 && char <= 0x39) ||   //0-9 
                 (char >= 0x61 && char <= 0x7a) ||   //a-z
                 (char == 0x2d && (i >= 1 && i <= 8)) || //-
                 (char == 0x00)){ 
                    return true;
                } else {
                    return false;
                }

    }

}