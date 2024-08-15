# Get Public Registration URLs in Traction Rec

Traction Rec offers a number of parameters to load filtered results in the Community Registration component when a user lands on a community page. This component gives internal users a way to quickly generate filtered URLs from Program, Course, and Course Session record pages.

## Docs

- [Project Quip](https://quip.com/Zp3FAf21WOuq/Get-Public-URL)
- [Deep Linking in Traction Rec](https://success.tractionrec.com/s/article/Web-Registration-URL-Parameters)

## Post-Installation Steps

1. **Add Get Public URL component** to Program, Course, and/or Course Session record pages.
2. **Add Traction Rec Get Public URL permission set** to users that should be able to access the component.
    - Alternatively, add the following access to an existing permission set:
        - **Apex Class**: `TRecRegistrationUrlBuilderCtrl`
        - **Custom Permission**: `Can Get Public URL`