Kubernetes - Keycloak

[![Keycloak](https://www.keycloak.org/resources/images/logo.svg)](https://www.keycloak.org/)[![GitHub stars](https://img.shields.io/github/stars/keycloak/keycloak?label=GitHub%20Stars)](https://github.com/keycloak/keycloak) [![GitHub stars](https://img.shields.io/github/stars/keycloak/keycloak?label=)](https://github.com/keycloak/keycloak)

Get started with Keycloak on Kubernetes

## Log in to the Admin Console

1.  Go to the Keycloak Admin Console.
2.  Log in with the username and password you created earlier.

## Create a realm

A realm in Keycloak is equivalent to a tenant. Each realm allows an administrator to create isolated groups of applications and users. Initially, Keycloak includes a single realm, called `master`. Use this realm only for managing Keycloak and not for managing any applications.

Use these steps to create the first realm.

1.  Open the Keycloak Admin Console.
2.  Click **Keycloak** next to **master realm**, then click **Create Realm**.
3.  Enter `myrealm` in the **Realm name** field.
4.  Click **Create**.

![Add realm](https://www.keycloak.org/resources/images/guides/add-realm.png)

## Create a user

Initially, the realm has no users. Use these steps to create a user:

1.  Verify that you are still in the **myrealm** realm, which is shown above the word **Manage**.
2.  Click **Users** in the left-hand menu.
3.  Click **Create new user**.
4.  Fill in the form with the following values:

    - **Username**: `myuser`
    - **First name**: any first name
    - **Last name**: any last name

5.  Click **Create**.

![Create user](https://www.keycloak.org/resources/images/guides/add-user.png)

This user needs a password to log in. To set the initial password:

1.  Click **Credentials** at the top of the page.
2.  Fill in the **Set password** form with a password.
3.  Toggle **Temporary** to **Off** so that the user does not need to update this password at the first login.

![Set password](https://www.keycloak.org/resources/images/guides/set-password.png)

## Log in to the Account Console

You can now log in to the Account Console to verify this user is configured correctly.

1.  Open the Keycloak Account Console.
2.  Log in with `myuser` and the password you created earlier.

As a user in the Account Console, you can manage your account including modifying your profile, adding two-factor authentication, and including identity provider accounts.

![Keycloak Account Console](https://www.keycloak.org/resources/images/guides/account-console.png)

## Secure the first application

To secure the first application, you start by registering the application with your Keycloak instance:

1.  Open the Keycloak Admin Console.
2.  Click the word **master** in the top-left corner, then click **myrealm**.
3.  Click **Clients**.
4.  Click **Create client**
5.  Fill in the form with the following values:

    - **Client type**: `OpenID Connect`
    - **Client ID**: `myclient`

      ![Add Client](https://www.keycloak.org/resources/images/guides/add-client-1.png)

6.  Click **Next**
7.  Confirm that **Standard flow** is enabled.
8.  Click **Next**.
9.  Make these changes under **Login settings**.

    - Set **Valid redirect URIs** to `https://www.keycloak.org/app/*`
    - Set **Web origins** to `https://www.keycloak.org`

10. Click **Save**.

![Update Client](https://www.keycloak.org/resources/images/guides/add-client-2.png)

To confirm the client was created successfully, you can use the SPA testing application on the [Keycloak website](https://www.keycloak.org/app/).

1.  Open [https://www.keycloak.org/app/](https://www.keycloak.org/app/).
2.  Change `Keycloak URL` to the URL of your Keycloak instance.
3.  Click **Save**.
4.  Click **Sign in** to authenticate to this application using the Keycloak server you started earlier.

## Taking the next step

Before you run Keycloak in production, consider the following actions:

- Switch to a production ready database such as PostgreSQL.
- Configure SSL with your own certificates.
- Switch the admin password to a more secure password.

For more information, see the [server guides](https://www.keycloak.org/guides#server).

Keycloak is a Cloud Native Computing Foundation incubation project

![Cloud Native Computing Foundation](https://www.keycloak.org/resources/images/cncf_logo.png)

© Keycloak Authors 2024. © 2024 The Linux Foundation. All rights reserved. The Linux Foundation has registered trademarks and uses trademarks. For a list of trademarks of The Linux Foundation, please see our [Trademark Usage page](https://www.linuxfoundation.org/trademark-usage).
