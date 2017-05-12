/*
    Copyright (c) 2016 Salesforce.org
    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Salesforce.com Foundation nor the names of
      its contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
    COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
    LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
    ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
    POSSIBILITY OF SUCH DAMAGE.
*/
/**
 * @author Salesforce.org
 * @group CampaignTools
 * @description Tests for CampaignTools_UTIL
 */
@isTest
    private with sharing class CampaignTools_TEST {
    /*******************************************************************************************************
     * @description Tests namespace fixup conditionally depending on whether a namespace is present
     *******************************************************************************************************/
    @isTest
    public static void TestNamespacePrefixFixups() {
        if (CampaignTools_UTIL.getNamespace()!='') {
            system.assertEquals(CampaignTools_UTIL.getNamespace()+'__foo', CampaignTools_UTIL.StrTokenNSPrefix('foo'));
            system.assertEquals(CampaignTools_UTIL.getNamespace()+'__foo__c', CampaignTools_UTIL.StrTokenNSPrefix('foo__c'));     
        } else {
            system.assertEquals('foo', CampaignTools_UTIL.StrTokenNSPrefix('foo'));
            system.assertEquals('foo__c', CampaignTools_UTIL.StrTokenNSPrefix('foo__c'));          
        }
    }
    /*******************************************************************************************************
     * @description Test invalid object name and assert and exception was caught
     *******************************************************************************************************/
    @isTest
    public static void TestInvalidObjectDescribe() {
        try {
            CampaignTools_UTIL.checkObjectCreateAccess('InvalidObjectName');
            System.assert(false, 'An exception should have occured.');
        } catch(Exception ex) {
            System.assert(true, 'An exception should occur.');
        }
    }
    /*******************************************************************************************************
     * @description Test invalid field name and assert and exception was caught
     *******************************************************************************************************/
    @isTest
    public static void TestInvalidFieldDescribe() {
        try {
            CampaignTools_UTIL.checkFieldCreateAccess('Campaign', 'InvalidFieldName');
            System.assert(false, 'An exception should have occured.');
        } catch(Exception ex) {
            System.assert(true, 'An exception should occur.');
        }
    }
    /*******************************************************************************************************
     * @description Test permissions exception, since CRUD cannot be set in a test, setting a flag on
     * CampaignTools_Util to simulate and asserting the exception was caught
     *******************************************************************************************************/
    @isTest
    public static void TestNoCreateAccess() {
        CampaignTools_UTIL.throwException = true;
        try {
            CampaignTools_UTIL.checkObjectCreateAccess('Campaign');
            System.assert(false, 'An exception should have occured.');
        } catch(Exception ex) {
            System.assert(true, 'An exception should occur.');
        }
    }
    /*******************************************************************************************************
     * @description Test permissions exception, since CRUD cannot be set in a test, setting a flag on
     * CampaignTools_Util to simulate and asserting the exception was caught
     *******************************************************************************************************/
    @isTest
    public static void TestNoReadAccess() {
        CampaignTools_UTIL.throwException = true;
        try {
            CampaignTools_UTIL.checkObjectReadAccess('Campaign');
            System.assert(false, 'An exception should have occured.');
        } catch(Exception ex) {
            System.assert(true, 'An exception should occur.');
        }
    }
    /*******************************************************************************************************
     * @description Test permissions exception, since CRUD cannot be set in a test, setting a flag on
     * CampaignTools_Util to simulate and asserting the exception was caught
     *******************************************************************************************************/
    @isTest
    public static void TestNoFieldCreateAccess() {
        CampaignTools_UTIL.throwException = true;
        try {
            CampaignTools_UTIL.checkFieldCreateAccess('Campaign', 'Name');
            System.assert(false, 'An exception should have occured.');
        } catch(Exception ex) {
            System.assert(true, 'An exception should occur.');
        }
    }
    /*******************************************************************************************************
     * @description Test permissions exception, since CRUD cannot be set in a test, setting a flag on
     * CampaignTools_Util to simulate and asserting the exception was caught
     *******************************************************************************************************/
    @isTest
    public static void TestNoDeleteAccess() {
        CampaignTools_UTIL.throwException = true;
        try {
            CampaignTools_UTIL.checkObjectDeleteAccess('Campaign');
            System.assert(false, 'An exception should have occured.');
        } catch(Exception ex) {
            System.assert(true, 'An exception should occur.');
        }
    }
}