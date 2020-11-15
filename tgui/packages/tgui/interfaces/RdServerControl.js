import { useBackend, useLocalState } from '../backend';
import { Box, Button, Collapsible, LabeledList, ProgressBar, Section, Tabs, Table, Flex } from '../components';
import { TableCell } from '../components/Table';
import { Window } from '../layouts';

export const RdServerControl = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    has_tech_disk,
    has_design_disk,
    rnd_servers,
    research_logs,
    tech_disk,
    design_disk,
    design_disk_size,
    tech_available,
  } = data;
  const [
    tabIndex,
    setTabIndex,
  ] = useLocalState(context, 'tab-index', 1);

  // Build design disk HTML here.
  // This has to be done here beacuse the way design disks work is obtuse.
  let design_html = [];
  if (has_design_disk) {
    for (let i = 0; i < design_disk_size; ++i) {
      design_html.push(
        <Box>
          {i+1}. {design_disk[i] ? design_disk[i].name : (
            <em>Empty</em>
          )}
        </Box>
      );
    }
  }

  return (
    <Window width={640} height={640}>
      <Window.Content scrollable>
        <Tabs>
          <Tabs.Tab
            selected={tabIndex === 1}
            onClick={() => setTabIndex(1)}>
            R&amp;D Server Control
          </Tabs.Tab>
          {!!has_tech_disk && (
            <Tabs.Tab
              selected={tabIndex === 3}
              onClick={() => setTabIndex(3)}>
              Technology Disk
            </Tabs.Tab>
          )}
          {!!has_design_disk && (
            <Tabs.Tab
              selected={tabIndex === 4}
              onClick={() => setTabIndex(4)}>
              Design Disk
            </Tabs.Tab>
          )}
          <Tabs.Tab
            selected={tabIndex === 2}
            onClick={() => setTabIndex(2)}>
            Research Log
          </Tabs.Tab>
        </Tabs>
        {tabIndex === 1 && (
          <Box>
            {rnd_servers.map(rnd_server => (
              <Section key={rnd_server.ref}
                title={rnd_server.name}
                buttons={(
                  <Button
                    icon="plug"
                    color={rnd_server.research_disabled ? "good" : "bad"}
                    onClick={() => act('rnd_server_power', {
                      rnd_server: rnd_server.ref,
                      research_disabled: !rnd_server.research_disabled,
                    })} />
                )}>
                <LabeledList>
                  <LabeledList.Item label="Temperature">
                    <Box color={rnd_server.current_temp_color}>
                      {rnd_server.current_temp}K
                    </Box>
                  </LabeledList.Item>
                  <LabeledList.Item label="Efficiency">
                    {(rnd_server.efficiency * 100)}%
                  </LabeledList.Item>
                  <LabeledList.Item label="Status">
                    {rnd_server.research_disabled
                      ? (<Box color="bad">Research Disabled</Box>)
                      : (<Box color="good">Research Enabled</Box>)}
                    {!!rnd_server.unpowered && (
                      <Box color="bad">Power Outage Detected</Box>
                    )}
                    {!!rnd_server.emped && (
                      <Box color="bad">Electrical Interference Detected</Box>
                    )}
                    {!!rnd_server.emagged && (
                      <Box color="bad">Firmware Errors Detected</Box>
                    )}
                  </LabeledList.Item>
                </LabeledList>
              </Section>
            ))}
          </Box>
        )}
        {tabIndex === 2 && (
          <Section key="Research Logs">
            <Table>
              <Table.Row header>
                <Table.Cell>Entry</Table.Cell>
                <Table.Cell>Research Name</Table.Cell>
                <Table.Cell>Cost</Table.Cell>
                <Table.Cell>Researcher Name</Table.Cell>
                <Table.Cell>Console Location</Table.Cell>
              </Table.Row>
              {research_logs.map((research_log, entryId) => (
                <Table.Row key={entryId}>
                  <Table.Cell>
                    {entryId+1}
                  </Table.Cell>
                  <Table.Cell>
                    {research_log[0]}
                  </Table.Cell>
                  <Table.Cell>
                    {research_log[1]}
                  </Table.Cell>
                  <Table.Cell>
                    {research_log[2]}
                  </Table.Cell>
                  <Table.Cell>
                    {research_log[3]}
                  </Table.Cell>
                </Table.Row>
              ))}
            </Table>
          </Section>
        )}
        {tabIndex === 3 && (
          <Flex direction="row" height="100%">
            <Flex.Item mr={1} grow={1}>
              <Section
                title="Technology Disk"
                buttons={(
                  <Box>
                    <Button
                      icon="trash"
                      color="bad"
                      onClick={() => { act('clear_tech'); }}>
                      Format
                    </Button>
                    <Button
                      icon="eject"
                      onClick={() => {
                        act('eject_disk');
                        setTabIndex(1);
                      }} />
                  </Box>
                )}>
                <Table>
                  {tech_disk.map(node => (
                    <Table.Row key={node.id}>
                      <Table.Cell>
                        {node.name}
                      </Table.Cell>
                    </Table.Row>
                  ))}
                </Table>
              </Section>
            </Flex.Item>
            <Flex.Item grow={1}>
              <Section
                title="Networked Research"
                buttons={(
                  <Box>
                    <Button
                      icon="copy"
                      color="good"
                      onClick={() => { act('copy_tech'); }}>
                      Copy
                    </Button>
                  </Box>
                )}>
                <Table>
                  {tech_available.map(node => (
                    <Table.Row key={node.id}>
                      <Table.Cell>
                        {node.name}
                      </Table.Cell>
                    </Table.Row>
                  ))}
                </Table>
              </Section>
            </Flex.Item>
          </Flex>
        )}
        {tabIndex === 4 && (
          <Box>
            <Section
              title="Design Disk"
              buttons={(
                <Button
                  color="bad"
                  icon="eject"
                  onClick={() => {
                    act('eject_disk');
                    setTabIndex(1);
                  }} />
              )}>
              <Table>
                {design_html}
              </Table>
            </Section>
          </Box>
        )}
      </Window.Content>
    </Window>
  );
};
