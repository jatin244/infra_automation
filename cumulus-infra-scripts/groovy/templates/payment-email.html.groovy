<!DOCTYPE html>
<html lang="en">

<head>
  <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
  <meta charset="UTF-8">
  <title>Payment-Pipeline</title>
</head>

<body style="margin: 0; padding: 0;">
  <table logopacing="0" style="width: 100%;border-collapse: collapse;">
    <thead style="background-color: #FFFFFF;">
      <tr>
        <td colspan="7" style="height: 32px;"></td>
      </tr>
      <tr>
        <td rowspan="2" colspan="1" style="padding-left: 10px;"></td>
        <td rowspan="2" colspan="2" style="padding: 0 0 10px 0;width: 100px;text-align: center;">
          <img style="width: 150px; height: 150px;" alt="logo" src="cid:priority-logo.png">
        </td>
        <td colspan="3" style="font-family: Lato-Bold, Helvetica; font-size: 15px; color: #343B49; letter-spacing: 1px; line-height: 16px; text-transform: uppercase; font-weight: bold;">
          ${jenkinsText}
        </td>
      </tr>
      <tr>
        <td colspan="4" style="font-family: Lato-Bold, Helvetica; font-size: 13px; color: #343B49;letter-spacing: 1px; line-height: 16px;"><br />
          <strong>Built By:</strong> ${builtBy} <br />
          <strong>Infra Scripts Branch:</strong> ${branch} <br />
          <strong>Infra Config Branch:</strong> ${configBranch} <br />
          <strong>Architecture:</strong> ${architecture} <br />
          <strong>Environment:</strong> ${environment} <br />
        </td>
      </tr>
      <tr>
        <td colspan="1" style="height: 10px; width: 30px"></td>
        <td colspan="2" style="height: 10px;"></td>
        <td colspan="3" style="height: 10px;"></td>
        <td colspan="1" style="height: 10px; width: 100px"></td>
      </tr>
    </thead>
    <tbody style="background-color: #F4F4F4;">
      <tr>
        <td colspan="1"></td>
        <td colspan="2" style="height: 24px;">
        </td>
        <td colspan="4"></td>
      </tr>
      <!--TABLE1-->
      <tr>
        <td rowspan="3" colspan="1"></td>
        <td rowspan="3" colspan="2" style="text-align: center;">
          <img style="width: 150px; height: 150px;" alt="devops" src="cid:devops-logo.png">
        </td>
        <td colspan="2" style="font-family: Lato-Bold, Helvetica; font-size: 13px; color: #343B49; letter-spacing: 1px; line-height: 16px;">
          <strong>${jenkinsJobName}</strong>
        </td>
        <td rowspan="3" colspan="2" style="padding-right: 24px;">
          <table logopacing="0" cellpadding="0" width="142px" style="text-align: center;">
            <tr>
              <td width="64px" height="142px">
                <a href="${jenkinsUrl}display/redirect" style="text-decoration: none;display: inline-block;height: 72px;width: 72px;line-height: 76px;text-align: center">
                  <img alt="arrow" style="max-width: 100%; max-height: 100%; display: block;" src="cid:arrow-logo.png">
                </a>
              </td>
            </tr>
          </table>
        </td>



      </tr>
      <tr>
        <td colspan="2" style="vertical-align: baseline; font-family: Lato, Helvetica; font-size: 16px; color: ${statusSuccess ? '#00D06D' : '#FF0082'}; letter-spacing: 1px; line-height: 16px; font-weight:900; text-transform: capitalize;">
          ${statusSuccess ? 'successful' : 'failed'}<br />
        </td>
      </tr>
      <tr>
        <td colspan="2" style="font-family: Lato-Bold, Helvetica; font-size: 12px; color: #343B49; letter-spacing: 2px; line-height: 16px;">
          <br /><strong>Operation:</strong> <span style="color: ${operation == 'apply' ? '#00D06D' : '#FF0082'}">${operation}</span> <br /><br />
          ${jenkinsStatus} <br />
          ${statusSuccess && operation == 'apply' ? wikiUrl : ''}
        </td>
      </tr>
      <!--TABLE1-->
      <tr>
        <td colspan="7" style="height: 32px;"></td>
      </tr>
    </tbody>
    <tfoot style="background-color: #F4F4F4;">
      <tr>
        <td colspan="2"></td>
        <td colspan="5" style="font-family: Lato-Bold, Helvetica; font-size: 10px; color: #AEAEAE; letter-spacing: 2px; line-height: 16px; margin-bottom: 0; text-transform: uppercase;">
        </td>
      </tr>
      <tr>
        <td colspan="2"></td>
        <td colspan="5" style="margin: 6px;">
        </td>
      </tr>
    </tfoot>
  </table>
</body>

</html>